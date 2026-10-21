#!/usr/bin/env python3
"""Validate a schema-v2 Godot guided feature task package."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


SKILL_VERSION = "2.0.0"

REQUIRED_FILES = {
    "TASK_MANIFEST.json",
    "TASK_STATE.json",
    "SCOPE_PROPOSAL.md",
    "DEVELOPMENT_PROMPT.md",
    "LEARNING_RECORD.md",
    "LEARNING_STATE.json",
    "INTEGRATION_HANDOFF.md",
}

MANIFEST_FIELDS = {
    "manifest_schema_version",
    "generated_by_skill_version",
    "task_id",
    "task_spec_version",
    "slug",
    "title",
    "engine_version",
    "development_strategy",
    "participation_mode",
    "execution_mode",
    "approval_status",
    "delivery_status",
    "learning_status",
    "handoff_status",
    "baseline_commit",
    "objective",
    "audit_freshness",
    "feature_ownership",
    "integration_contract",
    "allowed_existing_files",
    "allowed_new_files",
    "forbidden_systems",
    "steps",
    "participation_checkpoints",
    "learning_contract",
    "scene_architecture",
    "required_automated_checks",
    "required_manual_checks",
    "comparison_analysis",
    "scope_change_triggers",
    "approval",
}

ENUMS = {
    "development_strategy": {"plan_driven", "behavior_guided", "hybrid"},
    "participation_mode": {
        "guided_co_development",
        "guided_practice",
        "independent_challenge",
    },
    "execution_mode": {"teaching", "batch"},
    "approval_status": {"awaiting", "approved", "superseded"},
    "delivery_status": {
        "proposed",
        "approved",
        "in_progress",
        "implemented",
        "verification_blocked",
        "review",
        "complete",
    },
    "learning_status": {
        "not_started",
        "in_progress",
        "participation_pending",
        "partially_demonstrated",
        "demonstrated",
    },
    "handoff_status": {"not_started", "pending", "ready", "integrated"},
}

EVIDENCE_TYPES = {
    "concept_explanation",
    "project_navigation",
    "editor_operation",
    "scene_tree_inspection",
    "signal_trace",
    "configuration_inspection",
    "test_execution",
    "result_interpretation",
    "error_diagnosis",
    "ai_diff_review",
    "parameter_adjustment",
    "guided_patch",
    "independent_patch",
}

UNDERSTANDING_LEVELS = {
    "introduced",
    "recognized",
    "explained",
    "applied",
    "diagnosed",
}

CAPABILITY_VALUES = {
    "unknown",
    "available",
    "installed",
    "declined",
    "not_needed",
    "unavailable",
}

ASSISTANCE_LEVELS = {"full", "structured", "minimal", "none"}


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def require_keys(self, value: Any, keys: set[str], label: str) -> None:
        if not isinstance(value, dict):
            self.error(f"{label} must be an object")
            return
        for key in sorted(keys - value.keys()):
            self.error(f"{label}.{key} is required")

    def string(self, value: Any, label: str, *, allow_empty: bool = False) -> None:
        if not isinstance(value, str) or (not allow_empty and not value.strip()):
            self.error(f"{label} must be a non-empty string")

    def string_list(self, value: Any, label: str) -> None:
        if not isinstance(value, list):
            self.error(f"{label} must be an array")
            return
        for index, item in enumerate(value):
            if not isinstance(item, str) or not item.strip():
                self.error(f"{label}[{index}] must be a non-empty string")

    def enum(self, value: Any, allowed: set[str], label: str) -> None:
        if value not in allowed:
            self.error(f"{label} must be one of: {', '.join(sorted(allowed))}")


def load_json(path: Path, validation: Validation) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        validation.error(f"missing required file: {path.name}")
    except json.JSONDecodeError as exc:
        validation.error(
            f"{path.name} is not valid JSON: line {exc.lineno}, column {exc.colno}: {exc.msg}"
        )
    except OSError as exc:
        validation.error(f"cannot read {path.name}: {exc}")
    return None


def task_directory(argument: str) -> Path:
    path = Path(argument).expanduser()
    return path.parent if path.name == "TASK_MANIFEST.json" else path


def validate_manifest(manifest: dict[str, Any], root: Path, v: Validation) -> None:
    v.require_keys(manifest, MANIFEST_FIELDS, "TASK_MANIFEST")

    if manifest.get("generated_by_skill_version") != SKILL_VERSION:
        v.error(f"generated_by_skill_version must be {SKILL_VERSION}")

    task_id = manifest.get("task_id")
    v.string(task_id, "TASK_MANIFEST.task_id")
    version = manifest.get("task_spec_version")
    if not isinstance(version, int) or isinstance(version, bool) or version < 1:
        v.error("TASK_MANIFEST.task_spec_version must be a positive integer")

    for key in ("slug", "title", "baseline_commit", "objective"):
        v.string(manifest.get(key), f"TASK_MANIFEST.{key}")
    if manifest.get("engine_version") != "4.7":
        v.error("TASK_MANIFEST.engine_version must be 4.7")

    for key, allowed in ENUMS.items():
        v.enum(manifest.get(key), allowed, f"TASK_MANIFEST.{key}")

    for key in (
        "allowed_existing_files",
        "allowed_new_files",
        "forbidden_systems",
        "required_automated_checks",
        "required_manual_checks",
        "scope_change_triggers",
    ):
        v.string_list(manifest.get(key), f"TASK_MANIFEST.{key}")

    audit = manifest.get("audit_freshness")
    v.require_keys(
        audit,
        {
            "audited_commit",
            "environment_checked_at",
            "engine_executable_source",
            "engine_version_detected",
            "audit_invalidation_triggers",
        },
        "TASK_MANIFEST.audit_freshness",
    )
    if isinstance(audit, dict):
        for key in (
            "audited_commit",
            "environment_checked_at",
            "engine_executable_source",
            "engine_version_detected",
        ):
            v.string(audit.get(key), f"TASK_MANIFEST.audit_freshness.{key}")
        v.string_list(
            audit.get("audit_invalidation_triggers"),
            "TASK_MANIFEST.audit_freshness.audit_invalidation_triggers",
        )

    ownership = manifest.get("feature_ownership")
    ownership_keys = {
        "owner_id",
        "owned_systems",
        "owned_scenes",
        "owned_scripts",
        "owned_config_tables",
    }
    v.require_keys(ownership, ownership_keys, "TASK_MANIFEST.feature_ownership")
    if isinstance(ownership, dict):
        v.string(ownership.get("owner_id"), "TASK_MANIFEST.feature_ownership.owner_id")
        for key in ownership_keys - {"owner_id"}:
            v.string_list(
                ownership.get(key), f"TASK_MANIFEST.feature_ownership.{key}"
            )

    integration = manifest.get("integration_contract")
    integration_keys = {
        "depends_on_tasks",
        "consumed_interfaces",
        "provided_interfaces",
        "emitted_signals",
        "received_signals",
        "shared_state",
        "registered_shared_changes",
        "conflict_hotspots",
        "required_integration_checks",
    }
    v.require_keys(integration, integration_keys, "TASK_MANIFEST.integration_contract")
    if isinstance(integration, dict):
        for key in integration_keys:
            v.string_list(integration.get(key), f"TASK_MANIFEST.integration_contract.{key}")

    steps = manifest.get("steps")
    if not isinstance(steps, list) or not steps:
        v.error("TASK_MANIFEST.steps must be a non-empty array")
    else:
        step_ids: set[str] = set()
        for index, step in enumerate(steps):
            label = f"TASK_MANIFEST.steps[{index}]"
            keys = {
                "step_id",
                "title",
                "behavior",
                "main_concept",
                "files",
                "automated_checks",
                "manual_checks",
            }
            v.require_keys(step, keys, label)
            if not isinstance(step, dict):
                continue
            for key in ("step_id", "title", "behavior", "main_concept"):
                v.string(step.get(key), f"{label}.{key}")
            step_id = step.get("step_id")
            if isinstance(step_id, str):
                if step_id in step_ids:
                    v.error(f"duplicate step_id: {step_id}")
                step_ids.add(step_id)
            for key in ("files", "automated_checks", "manual_checks"):
                v.string_list(step.get(key), f"{label}.{key}")

    checkpoints = manifest.get("participation_checkpoints")
    required_checkpoint_types = {"orientation", "inspection", "verification_handoff"}
    found_checkpoint_types: set[str] = set()
    checkpoint_ids: set[str] = set()
    if not isinstance(checkpoints, list):
        v.error("TASK_MANIFEST.participation_checkpoints must be an array")
    else:
        for index, checkpoint in enumerate(checkpoints):
            label = f"TASK_MANIFEST.participation_checkpoints[{index}]"
            v.require_keys(
                checkpoint,
                {"checkpoint_id", "type", "required", "evidence_types"},
                label,
            )
            if not isinstance(checkpoint, dict):
                continue
            checkpoint_id = checkpoint.get("checkpoint_id")
            v.string(checkpoint_id, f"{label}.checkpoint_id")
            if isinstance(checkpoint_id, str):
                if checkpoint_id in checkpoint_ids:
                    v.error(f"duplicate checkpoint_id: {checkpoint_id}")
                checkpoint_ids.add(checkpoint_id)
            checkpoint_type = checkpoint.get("type")
            v.enum(checkpoint_type, required_checkpoint_types, f"{label}.type")
            if isinstance(checkpoint_type, str):
                found_checkpoint_types.add(checkpoint_type)
            if checkpoint.get("required") is not True:
                v.error(f"{label}.required must be true")
            evidence_types = checkpoint.get("evidence_types")
            if not isinstance(evidence_types, list) or not evidence_types:
                v.error(f"{label}.evidence_types must be a non-empty array")
            else:
                for evidence_type in evidence_types:
                    v.enum(evidence_type, EVIDENCE_TYPES, f"{label}.evidence_types")
        missing = required_checkpoint_types - found_checkpoint_types
        if missing:
            v.error(
                "participation_checkpoints missing required types: "
                + ", ".join(sorted(missing))
            )

    learning_contract = manifest.get("learning_contract")
    learning_keys = {
        "objectives",
        "concepts",
        "required_evidence_types",
        "required_student_outcomes",
    }
    v.require_keys(learning_contract, learning_keys, "TASK_MANIFEST.learning_contract")
    if isinstance(learning_contract, dict):
        for key in ("objectives", "concepts", "required_student_outcomes"):
            v.string_list(
                learning_contract.get(key), f"TASK_MANIFEST.learning_contract.{key}"
            )
        evidence_types = learning_contract.get("required_evidence_types")
        if not isinstance(evidence_types, list):
            v.error("TASK_MANIFEST.learning_contract.required_evidence_types must be an array")
        else:
            for evidence_type in evidence_types:
                v.enum(
                    evidence_type,
                    EVIDENCE_TYPES,
                    "TASK_MANIFEST.learning_contract.required_evidence_types",
                )

    validate_scene_architecture(manifest.get("scene_architecture"), v)
    validate_comparison(manifest.get("comparison_analysis"), manifest, root, v)
    validate_approval(manifest, v)

    strategy = manifest.get("development_strategy")
    behavior_spec = root / "BEHAVIOR_SPEC.md"
    if strategy in {"behavior_guided", "hybrid"} and not behavior_spec.is_file():
        v.error(f"BEHAVIOR_SPEC.md is required for {strategy}")


def validate_scene_architecture(value: Any, v: Validation) -> None:
    label = "TASK_MANIFEST.scene_architecture"
    keys = {
        "architecture_change",
        "entry_scene",
        "lifecycle_rationale",
        "current_tree",
        "target_tree",
        "ownership",
        "signal_contracts",
        "loading_policy",
        "state_persistence",
        "animation_dependencies",
        "lifecycle_checks",
    }
    v.require_keys(value, keys, label)
    if not isinstance(value, dict):
        return
    architecture_change = value.get("architecture_change")
    if not isinstance(architecture_change, bool):
        v.error(f"{label}.architecture_change must be a boolean")
        return
    v.string(value.get("entry_scene"), f"{label}.entry_scene")
    v.string(value.get("lifecycle_rationale"), f"{label}.lifecycle_rationale")
    for key in (
        "ownership",
        "signal_contracts",
        "state_persistence",
        "animation_dependencies",
        "lifecycle_checks",
    ):
        if not isinstance(value.get(key), list):
            v.error(f"{label}.{key} must be an array")

    if architecture_change:
        for key in ("current_tree", "target_tree", "loading_policy"):
            item = value.get(key)
            if item is None or item == "" or item == {} or item == []:
                v.error(f"{label}.{key} must be concrete when architecture_change is true")
        for key in ("ownership", "signal_contracts", "lifecycle_checks"):
            if not isinstance(value.get(key), list) or not value.get(key):
                v.error(f"{label}.{key} must be non-empty when architecture_change is true")
    else:
        for key in ("current_tree", "target_tree", "loading_policy"):
            if value.get(key) is not None:
                v.error(f"{label}.{key} must be null when architecture_change is false")
        for key in (
            "ownership",
            "signal_contracts",
            "state_persistence",
            "animation_dependencies",
            "lifecycle_checks",
        ):
            if value.get(key) != []:
                v.error(f"{label}.{key} must be empty when architecture_change is false")


def validate_comparison(
    value: Any, manifest: dict[str, Any], root: Path, v: Validation
) -> None:
    label = "TASK_MANIFEST.comparison_analysis"
    keys = {
        "available",
        "scope",
        "read_only",
        "behavior_spec",
        "observed_contracts",
        "deliberate_differences",
        "unknowns",
    }
    v.require_keys(value, keys, label)
    if not isinstance(value, dict):
        return
    if not isinstance(value.get("available"), bool):
        v.error(f"{label}.available must be a boolean")
    if value.get("read_only") is not True:
        v.error(f"{label}.read_only must be true")
    v.string(value.get("scope"), f"{label}.scope")
    behavior_spec = value.get("behavior_spec")
    if behavior_spec is not None:
        v.string(behavior_spec, f"{label}.behavior_spec")
    for key in ("observed_contracts", "deliberate_differences", "unknowns"):
        v.string_list(value.get(key), f"{label}.{key}")

    strategy = manifest.get("development_strategy")
    if strategy in {"behavior_guided", "hybrid"}:
        if value.get("available") is not True:
            v.error(f"{label}.available must be true for {strategy}")
        if behavior_spec != "BEHAVIOR_SPEC.md":
            v.error(
                f"{label}.behavior_spec must be BEHAVIOR_SPEC.md for {strategy}"
            )
    elif value.get("available") is False and behavior_spec is not None:
        v.error(f"{label}.behavior_spec must be null when comparison is unavailable")

    if behavior_spec == "BEHAVIOR_SPEC.md" and not (root / behavior_spec).is_file():
        v.error(f"{label}.behavior_spec points to missing BEHAVIOR_SPEC.md")


def validate_approval(manifest: dict[str, Any], v: Validation) -> None:
    approval = manifest.get("approval")
    label = "TASK_MANIFEST.approval"
    keys = {
        "approved",
        "approved_version",
        "approved_at",
        "exact_user_text",
        "canonical_example",
    }
    v.require_keys(approval, keys, label)
    if not isinstance(approval, dict):
        return
    if not isinstance(approval.get("approved"), bool):
        v.error(f"{label}.approved must be a boolean")
    v.string(approval.get("canonical_example"), f"{label}.canonical_example")

    status = manifest.get("approval_status")
    delivery = manifest.get("delivery_status")
    version = manifest.get("task_spec_version")
    if status == "awaiting":
        if approval.get("approved") is not False:
            v.error("approval_status=awaiting requires approval.approved=false")
        if delivery != "proposed":
            v.error("approval_status=awaiting requires delivery_status=proposed")
        for key in ("approved_version", "approved_at", "exact_user_text"):
            if approval.get(key) is not None:
                v.error(f"approval_status=awaiting requires approval.{key}=null")
    elif status == "approved":
        if approval.get("approved") is not True:
            v.error("approval_status=approved requires approval.approved=true")
        if approval.get("approved_version") != version:
            v.error("approval.approved_version must match task_spec_version")
        v.string(approval.get("approved_at"), f"{label}.approved_at")
        v.string(approval.get("exact_user_text"), f"{label}.exact_user_text")
        if delivery != "approved":
            v.error(
                "TASK_MANIFEST approval_status=approved requires the immutable "
                "delivery_status snapshot to be approved"
            )
    elif status == "superseded" and delivery == "complete":
        v.error("approval_status=superseded cannot use delivery_status=complete")

    if manifest.get("handoff_status") == "integrated":
        if delivery != "complete":
            v.error("handoff_status=integrated requires delivery_status=complete")


def validate_state(
    state: dict[str, Any], manifest: dict[str, Any], v: Validation
) -> None:
    label = "TASK_STATE"
    keys = {
        "task_id",
        "task_spec_version",
        "approval_status",
        "delivery_status",
        "learning_status",
        "handoff_status",
        "current_step",
        "current_checkpoint",
        "next_action",
        "implementation_baseline",
        "last_verified_commit",
        "integration_baseline_commit",
        "step_state",
        "approval_record",
        "capability_decisions",
    }
    v.require_keys(state, keys, label)
    if not isinstance(state, dict):
        return
    validate_identity(state, manifest, label, v)
    for key in ("approval_status", "delivery_status", "learning_status", "handoff_status"):
        v.enum(state.get(key), ENUMS[key], f"{label}.{key}")
    if state.get("approval_status") != manifest.get("approval_status"):
        v.error(f"{label}.approval_status must match TASK_MANIFEST.approval_status")
    if state.get("current_step") is not None:
        v.string(state.get("current_step"), f"{label}.current_step")
        declared_steps = {
            step.get("step_id")
            for step in manifest.get("steps", [])
            if isinstance(step, dict) and isinstance(step.get("step_id"), str)
        }
        if state.get("current_step") not in declared_steps:
            v.error(f"{label}.current_step must reference TASK_MANIFEST.steps")
    if state.get("current_checkpoint") is not None:
        v.string(state.get("current_checkpoint"), f"{label}.current_checkpoint")
        declared_checkpoints = {
            checkpoint.get("checkpoint_id")
            for checkpoint in manifest.get("participation_checkpoints", [])
            if isinstance(checkpoint, dict)
            and isinstance(checkpoint.get("checkpoint_id"), str)
        }
        if state.get("current_checkpoint") not in declared_checkpoints:
            v.error(
                f"{label}.current_checkpoint must reference "
                "TASK_MANIFEST.participation_checkpoints"
            )
    v.string(state.get("next_action"), f"{label}.next_action")
    if not isinstance(state.get("step_state"), list):
        v.error(f"{label}.step_state must be an array")

    baseline = state.get("implementation_baseline")
    v.require_keys(
        baseline, {"captured_at", "commit", "preexisting_changes"}, f"{label}.implementation_baseline"
    )
    if isinstance(baseline, dict):
        for key in ("captured_at", "commit"):
            if baseline.get(key) is not None:
                v.string(baseline.get(key), f"{label}.implementation_baseline.{key}")
        changes = baseline.get("preexisting_changes")
        if not isinstance(changes, list):
            v.error(f"{label}.implementation_baseline.preexisting_changes must be an array")
        else:
            for index, change in enumerate(changes):
                change_label = f"{label}.implementation_baseline.preexisting_changes[{index}]"
                v.require_keys(change, {"path", "status", "fingerprint"}, change_label)
                if isinstance(change, dict):
                    v.string(change.get("path"), f"{change_label}.path")
                    v.string_list(change.get("status"), f"{change_label}.status")
                    v.string(change.get("fingerprint"), f"{change_label}.fingerprint")
        captured_at = baseline.get("captured_at")
        commit = baseline.get("commit")
        if (captured_at is None) != (commit is None):
            v.error(
                f"{label}.implementation_baseline.captured_at and commit must both be "
                "null or both be populated"
            )

    for key in ("last_verified_commit", "integration_baseline_commit"):
        if state.get(key) is not None:
            v.string(state.get(key), f"{label}.{key}")

    approval_record = state.get("approval_record")
    v.require_keys(
        approval_record,
        {"approved_version", "approved_at", "exact_user_text"},
        f"{label}.approval_record",
    )
    manifest_approval = manifest.get("approval")
    if isinstance(approval_record, dict) and isinstance(manifest_approval, dict):
        mapping = {
            "approved_version": "approved_version",
            "approved_at": "approved_at",
            "exact_user_text": "exact_user_text",
        }
        for state_key, manifest_key in mapping.items():
            if approval_record.get(state_key) != manifest_approval.get(manifest_key):
                v.error(
                    f"{label}.approval_record.{state_key} must match "
                    f"TASK_MANIFEST.approval.{manifest_key}"
                )

    capabilities = state.get("capability_decisions")
    capability_keys = {"superpowers", "godot_skill", "code_review"}
    v.require_keys(capabilities, capability_keys, f"{label}.capability_decisions")
    if isinstance(capabilities, dict):
        for key in capability_keys:
            v.enum(
                capabilities.get(key),
                CAPABILITY_VALUES,
                f"{label}.capability_decisions.{key}",
            )

    if state.get("handoff_status") in {"ready", "integrated"}:
        if state.get("delivery_status") != "complete":
            v.error(
                "TASK_STATE handoff_status=ready or integrated requires "
                "delivery_status=complete"
            )
    if state.get("handoff_status") == "integrated":
        if not state.get("integration_baseline_commit"):
            v.error("TASK_STATE.integration_baseline_commit is required when handoff is integrated")

    approval_status = state.get("approval_status")
    delivery_status = state.get("delivery_status")
    if approval_status == "awaiting" and delivery_status != "proposed":
        v.error("TASK_STATE approval_status=awaiting requires delivery_status=proposed")
    if approval_status == "approved" and delivery_status == "proposed":
        v.error("TASK_STATE approval_status=approved cannot use delivery_status=proposed")
    if approval_status == "superseded" and delivery_status == "complete":
        v.error("TASK_STATE approval_status=superseded cannot use delivery_status=complete")
    if delivery_status == "complete" and not state.get("last_verified_commit"):
        v.error("TASK_STATE.last_verified_commit is required when delivery is complete")


def validate_learning(
    learning: dict[str, Any],
    manifest: dict[str, Any],
    state: dict[str, Any],
    v: Validation,
) -> None:
    label = "LEARNING_STATE"
    keys = {
        "task_id",
        "task_spec_version",
        "learning_status",
        "concepts_introduced",
        "concepts_explained_by_student",
        "editor_operations_completed",
        "verification_completed",
        "integration_contract_understood",
        "student_questions",
        "unresolved_concepts",
        "assistance_level",
        "evidence",
    }
    v.require_keys(learning, keys, label)
    if not isinstance(learning, dict):
        return
    validate_identity(learning, manifest, label, v)
    v.enum(learning.get("learning_status"), ENUMS["learning_status"], f"{label}.learning_status")
    if learning.get("learning_status") != state.get("learning_status"):
        v.error(f"{label}.learning_status must match TASK_STATE.learning_status")
    for key in (
        "concepts_introduced",
        "concepts_explained_by_student",
        "editor_operations_completed",
        "verification_completed",
        "student_questions",
        "unresolved_concepts",
    ):
        v.string_list(learning.get(key), f"{label}.{key}")
    if learning.get("integration_contract_understood") not in {None, True, False}:
        v.error(f"{label}.integration_contract_understood must be true, false, or null")
    v.enum(learning.get("assistance_level"), ASSISTANCE_LEVELS, f"{label}.assistance_level")

    evidence = learning.get("evidence")
    if not isinstance(evidence, list):
        v.error(f"{label}.evidence must be an array")
        return
    declared_steps = {
        step.get("step_id")
        for step in manifest.get("steps", [])
        if isinstance(step, dict) and isinstance(step.get("step_id"), str)
    }
    declared_checkpoints = {
        checkpoint.get("checkpoint_id")
        for checkpoint in manifest.get("participation_checkpoints", [])
        if isinstance(checkpoint, dict)
        and isinstance(checkpoint.get("checkpoint_id"), str)
    }
    for index, item in enumerate(evidence):
        item_label = f"{label}.evidence[{index}]"
        keys = {
            "evidence_type",
            "step_id",
            "checkpoint_id",
            "summary",
            "understanding_level",
            "observed_at",
        }
        v.require_keys(item, keys, item_label)
        if not isinstance(item, dict):
            continue
        v.enum(item.get("evidence_type"), EVIDENCE_TYPES, f"{item_label}.evidence_type")
        v.enum(
            item.get("understanding_level"),
            UNDERSTANDING_LEVELS,
            f"{item_label}.understanding_level",
        )
        for key in ("step_id", "checkpoint_id", "summary", "observed_at"):
            v.string(item.get(key), f"{item_label}.{key}")
        if item.get("step_id") not in declared_steps:
            v.error(f"{item_label}.step_id must reference TASK_MANIFEST.steps")
        if item.get("checkpoint_id") not in declared_checkpoints:
            v.error(
                f"{item_label}.checkpoint_id must reference "
                "TASK_MANIFEST.participation_checkpoints"
            )


def validate_identity(
    value: dict[str, Any], manifest: dict[str, Any], label: str, v: Validation
) -> None:
    if value.get("task_id") != manifest.get("task_id"):
        v.error(f"{label}.task_id must match TASK_MANIFEST.task_id")
    if value.get("task_spec_version") != manifest.get("task_spec_version"):
        v.error(f"{label}.task_spec_version must match TASK_MANIFEST.task_spec_version")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_task.py <task-directory-or-TASK_MANIFEST.json>", file=sys.stderr)
        return 1

    root = task_directory(sys.argv[1]).resolve()
    manifest_path = root / "TASK_MANIFEST.json"
    if not manifest_path.is_file():
        print(f"ERROR: missing TASK_MANIFEST.json under {root}", file=sys.stderr)
        return 1

    try:
        with manifest_path.open("r", encoding="utf-8") as handle:
            manifest_probe = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot parse TASK_MANIFEST.json: {exc}", file=sys.stderr)
        return 1

    schema = manifest_probe.get("manifest_schema_version") if isinstance(manifest_probe, dict) else None
    if schema != 2:
        print(
            "MIGRATION REQUIRED: this task package does not use manifest_schema_version 2. "
            "Regenerate or migrate it before implementation; historical files were not modified.",
            file=sys.stderr,
        )
        return 2

    validation = Validation()
    for name in sorted(REQUIRED_FILES):
        if not (root / name).is_file():
            validation.error(f"missing required file: {name}")

    manifest = manifest_probe
    state = load_json(root / "TASK_STATE.json", validation)
    learning = load_json(root / "LEARNING_STATE.json", validation)

    if isinstance(manifest, dict):
        validate_manifest(manifest, root, validation)
    else:
        validation.error("TASK_MANIFEST.json must contain an object")
    if isinstance(state, dict) and isinstance(manifest, dict):
        validate_state(state, manifest, validation)
    elif state is not None:
        validation.error("TASK_STATE.json must contain an object")
    if isinstance(learning, dict):
        if isinstance(manifest, dict) and isinstance(state, dict):
            validate_learning(learning, manifest, state, validation)
    elif learning is not None:
        validation.error("LEARNING_STATE.json must contain an object")

    if validation.errors:
        print(f"INVALID: {root}", file=sys.stderr)
        for error in validation.errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"VALID: {manifest.get('task_id')} v{manifest.get('task_spec_version')} "
        f"({manifest.get('development_strategy')})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
