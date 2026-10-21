#!/usr/bin/env python3
"""Capture and check a task's Git implementation scope without modifying worktree files."""

from __future__ import annotations

import fnmatch
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def fail(message: str, code: int = 1) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return code


def run_git(root: Path, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        ["git", "-C", str(root), *arguments],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"git {' '.join(arguments)} failed: {detail}")
    return result


def repository_root(task_dir: Path) -> Path:
    result = subprocess.run(
        ["git", "-C", str(task_dir), "rev-parse", "--show-toplevel"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "task directory is not inside a Git repository")
    return Path(result.stdout.strip()).resolve()


def nul_paths(result: subprocess.CompletedProcess[bytes]) -> set[str]:
    return {
        item.decode("utf-8", errors="surrogateescape")
        for item in result.stdout.split(b"\0")
        if item
    }


def working_status(root: Path) -> dict[str, set[str]]:
    statuses: dict[str, set[str]] = {}
    commands = {
        "staged": ("diff", "--cached", "--name-only", "-z"),
        "unstaged": ("diff", "--name-only", "-z"),
        "untracked": ("ls-files", "--others", "--exclude-standard", "-z"),
    }
    for status, command in commands.items():
        for path in nul_paths(run_git(root, *command)):
            statuses.setdefault(path, set()).add(status)
    return statuses


def worktree_fingerprint(root: Path, relative_path: str) -> str:
    path = root / relative_path
    if not path.exists() and not path.is_symlink():
        return "missing"
    digest = hashlib.sha256()
    digest.update(f"mode:{path.lstat().st_mode:o}\0".encode("ascii"))
    if path.is_symlink():
        digest.update(b"symlink\0")
        digest.update(path.readlink().as_posix().encode("utf-8", errors="surrogateescape"))
        return "sha256:" + digest.hexdigest()
    if not path.is_file():
        return "non-regular"
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def fingerprint(root: Path, relative_path: str) -> str:
    digest = hashlib.sha256()
    digest.update(worktree_fingerprint(root, relative_path).encode("ascii"))
    digest.update(b"\0index\0")
    index_entry = run_git(
        root, "ls-files", "--stage", "-z", "--", relative_path
    ).stdout
    digest.update(index_entry)
    return "sha256:" + digest.hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            value = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"cannot read {path.name}: {exc}") from exc
    if not isinstance(value, dict):
        raise RuntimeError(f"{path.name} must contain a JSON object")
    return value


def write_json(path: Path, value: dict[str, Any]) -> None:
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    temporary.replace(path)


def current_commit(root: Path) -> str:
    return run_git(root, "rev-parse", "HEAD").stdout.decode().strip()


def capture(task_dir: Path, root: Path) -> int:
    manifest = load_json(task_dir / "TASK_MANIFEST.json")
    state_path = task_dir / "TASK_STATE.json"
    state = load_json(state_path)
    baseline = state.get("implementation_baseline")
    if not isinstance(baseline, dict):
        raise RuntimeError("TASK_STATE.implementation_baseline must be an object")
    if baseline.get("captured_at") is not None or baseline.get("commit") is not None:
        raise RuntimeError(
            "implementation baseline is already captured; create a new task version instead of recapturing"
        )
    if state.get("task_id") != manifest.get("task_id") or state.get(
        "task_spec_version"
    ) != manifest.get("task_spec_version"):
        raise RuntimeError("TASK_STATE identity does not match TASK_MANIFEST")
    if state.get("approval_status") != "approved" or state.get("delivery_status") != "approved":
        raise RuntimeError(
            "capture requires approval_status=approved and delivery_status=approved"
        )

    approved_baseline = manifest.get("baseline_commit")
    if not isinstance(approved_baseline, str) or not approved_baseline:
        raise RuntimeError("TASK_MANIFEST.baseline_commit must be a non-empty commit")
    ancestry = run_git(
        root, "merge-base", "--is-ancestor", approved_baseline, "HEAD", check=False
    )
    if ancestry.returncode != 0:
        raise RuntimeError(
            "current HEAD does not descend from TASK_MANIFEST.baseline_commit"
        )

    statuses = working_status(root)
    preexisting = [
        {
            "path": path,
            "status": sorted(statuses[path]),
            "fingerprint": fingerprint(root, path),
        }
        for path in sorted(statuses)
    ]
    baseline["captured_at"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    baseline["commit"] = current_commit(root)
    baseline["preexisting_changes"] = preexisting
    write_json(state_path, state)

    print(
        f"CAPTURED: commit {baseline['commit']} with "
        f"{len(preexisting)} pre-existing changed path(s)"
    )
    return 0


def changed_since(root: Path, baseline: str) -> tuple[set[str], dict[str, set[str]]]:
    verify = run_git(root, "cat-file", "-e", f"{baseline}^{{commit}}", check=False)
    if verify.returncode != 0:
        raise RuntimeError(f"implementation baseline commit does not exist: {baseline}")
    ancestry = run_git(root, "merge-base", "--is-ancestor", baseline, "HEAD", check=False)
    if ancestry.returncode != 0:
        raise RuntimeError("current HEAD does not descend from implementation baseline commit")
    committed = nul_paths(run_git(root, "diff", "--name-only", "-z", f"{baseline}..HEAD"))
    statuses = working_status(root)
    return committed | set(statuses), statuses


def normalize_rule(rule: str) -> str:
    normalized = rule.strip().replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def matches(path: str, rules: list[str]) -> bool:
    for raw_rule in rules:
        rule = normalize_rule(raw_rule)
        if not rule:
            continue
        if rule.endswith("/") and path.startswith(rule):
            return True
        if any(character in rule for character in "*?[") and fnmatch.fnmatchcase(path, rule):
            return True
        if path == rule:
            return True
    return False


def existed_at(root: Path, commit: str, path: str) -> bool:
    result = run_git(root, "cat-file", "-e", f"{commit}:{path}", check=False)
    return result.returncode == 0


def validate_rules(value: Any, label: str) -> list[str]:
    if not isinstance(value, list) or any(not isinstance(item, str) for item in value):
        raise RuntimeError(f"{label} must be an array of strings")
    return value


def check_scope(task_dir: Path, root: Path) -> int:
    manifest = load_json(task_dir / "TASK_MANIFEST.json")
    state = load_json(task_dir / "TASK_STATE.json")
    existing_rules = validate_rules(
        manifest.get("allowed_existing_files"), "TASK_MANIFEST.allowed_existing_files"
    )
    new_rules = validate_rules(manifest.get("allowed_new_files"), "TASK_MANIFEST.allowed_new_files")

    baseline = state.get("implementation_baseline")
    if not isinstance(baseline, dict):
        raise RuntimeError("TASK_STATE.implementation_baseline must be an object")
    baseline_commit = baseline.get("commit")
    if not isinstance(baseline_commit, str) or not baseline_commit:
        raise RuntimeError("implementation baseline has not been captured")

    captured_changes = baseline.get("preexisting_changes")
    if not isinstance(captured_changes, list):
        raise RuntimeError("implementation_baseline.preexisting_changes must be an array")
    captured: dict[str, dict[str, Any]] = {}
    for item in captured_changes:
        if not isinstance(item, dict) or not isinstance(item.get("path"), str):
            raise RuntimeError("invalid pre-existing change entry in TASK_STATE.json")
        captured[item["path"]] = item

    changed, statuses = changed_since(root, baseline_commit)
    ignored: list[str] = []
    allowed: list[str] = []
    violations: list[str] = []

    for path in sorted(changed):
        current_status = sorted(statuses.get(path, set()))
        old = captured.get(path)
        if (
            old is not None
            and old.get("status") == current_status
            and old.get("fingerprint") == fingerprint(root, path)
        ):
            ignored.append(path)
            continue

        is_new = not existed_at(root, baseline_commit, path)
        rules = new_rules if is_new else existing_rules
        category = "new" if is_new else "existing"
        if matches(path, rules):
            allowed.append(f"{category}: {path}")
        else:
            violations.append(f"{category}: {path}")

    print(
        f"SCOPE: {len(allowed)} allowed, {len(ignored)} unchanged pre-existing, "
        f"{len(violations)} violation(s)"
    )
    for item in allowed:
        print(f"ALLOW  {item}")
    for path in ignored:
        print(f"IGNORE pre-existing: {path}")
    for item in violations:
        print(f"VIOLATION {item}")
    return 1 if violations else 0


def task_directory(argument: str) -> Path:
    path = Path(argument).expanduser()
    return path.parent if path.name == "TASK_MANIFEST.json" else path


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in {"capture", "check"}:
        print(
            "usage: check_task_scope.py <capture|check> <task-directory-or-TASK_MANIFEST.json>",
            file=sys.stderr,
        )
        return 1
    task_dir = task_directory(sys.argv[2]).resolve()
    try:
        root = repository_root(task_dir)
        if sys.argv[1] == "capture":
            return capture(task_dir, root)
        return check_scope(task_dir, root)
    except RuntimeError as exc:
        return fail(str(exc))


if __name__ == "__main__":
    raise SystemExit(main())
