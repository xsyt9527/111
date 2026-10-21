# Implementation, Verification, And Review

## Pre-implementation gate

Before gameplay edits:

1. Run `validate_task.py` and require schema-v2 success.
2. Confirm task ID, `task_spec_version`, `approval_status=approved`, matching approved version, exact user approval text, and `delivery_status=approved`.
3. Confirm current Git commit descends from the manifest baseline.
4. Inspect staged, unstaged, and untracked changes. Resolve ownership ambiguity before editing.
5. Run `check_task_scope.py capture <task-dir>` to store the implementation commit and fingerprints for pre-existing dirty files.
6. Confirm active Step files, acceptance criteria, feature ownership, integration contract, and scene architecture decision.
7. For `behavior_guided` or `hybrid`, confirm `BEHAVIOR_SPEC.md` is self-contained.
8. Resolve Godot, run `--version`, require major/minor 4.7 for certified checks, and store executable source/version in `TASK_STATE.json`.
9. Persist Superpowers, Godot Skill, and code-review capability decisions. Ask at most once for missing requested adapters.

Planning documents may change before approval. Production scripts, scenes, resources, and gameplay configuration may not.

Baseline capture is single-use for a task version. Do not recapture after implementation begins to hide new changes; revise the task version when a new implementation baseline is genuinely required. Captured fingerprints cover both working-tree content/metadata and the Git index entry.

## Teaching flow

Development Steps and learning checkpoints are independent. Do not stop after every function.

### Orientation checkpoint

Before the first implementation slice:

1. Explain the feature purpose and observable result.
2. Show exact relevant folders, scenes, scripts, configuration, and tests.
3. Explain one core concept using the beginner explanation rule.
4. Offer at most two bounded design options and recommend one.
5. Ask the student to locate one artifact and confirm the choice or explain the expected flow.
6. Record objective evidence in `LEARNING_STATE.json` and `LEARNING_RECORD.md`.

Correct misunderstandings before implementation. Do not require the student to design the whole system.

If the student first says they do not know or cannot perform the requested action, immediately demonstrate the smallest complete example. Then ask the student to restate the principle or inspect one named result. If they still cannot identify it, state the correct observation, record the concept as unresolved, and continue the approved activity. Do not repeat the same unanswered question or leave the workflow waiting indefinitely. Record the demonstration as `introduced`; record a higher level only from the student's observed response. Only a real approval, scope, dependency, environment, or verification blocker stops delivery.

### Implement and verify one slice

1. Restate the approved behavior, files, ownership, interfaces, and pass criteria.
2. AI implements the coherent slice within the allowlist. In `guided_practice` or `independent_challenge`, reserve only the explicitly approved student work.
3. Run the slice's automated checks.
4. Run required Godot 4.7 checks when available.
5. Explain what each check proves and what remains unverified.
6. Run scope checking and inspect the diff for ownership or public-interface drift.
7. Update implementation, verification, and task state.

### Godot inspection checkpoint

Guide the student through one focused inspection using exact editor navigation, for example:

```text
FileSystem -> scenes/shop/ShopView.tscn
-> Scene dock -> ShopView/OfferGrid
-> Inspector -> Script
-> inspect signal offer_selected and its connection owner
```

Ask the student to report one observable fact: node owner, script attachment, signal direction, configuration ID, test result, or lifecycle behavior. Record only the response or action actually observed.

If the Godot editor operation is temporarily unavailable, show the focused `.tscn`, script, configuration entry, screenshot, test result, or captured log instead. Ask the student to identify one named fact. Record the actual evidence type and understanding level; do not claim an editor operation or `applied` understanding from this substitute. Required runtime or Godot 4.7 checks remain required.

### Verification and handoff checkpoint

The student runs or interprets at least one verification result, then identifies:

- Runtime entry point.
- Inputs and outputs.
- Dependencies and provided interfaces.
- State owner.
- One failure investigation path.
- Integration method and forbidden direct access.

Update learning and handoff state separately from delivery state.

In `teaching`, stop at meaningful checkpoints and use the demonstration rule when the student is blocked. In `batch`, continue through approved Steps without checkpoint pauses and keep unobserved learning evidence `participation_pending`; never invent answers.

### Pause and resume state

Before every checkpoint pause or session end, update `TASK_STATE.json` and the relevant Step state with:

- Current Step and checkpoint IDs.
- The implementation and checks already completed.
- The exact next student action.
- The exact file, scene, node, signal, configuration entry, or report to open.
- The current technical blocker or unresolved concept, if any.

On resume, read `TASK_STATE.json`, `LEARNING_STATE.json`, and `INTEGRATION_HANDOFF.md` first. Restate the current location and next action briefly, then continue from that point without depending on earlier conversation history. Students working at different times coordinate through task ownership, declared interfaces, and verified handoffs.

## Verification layers

### Static and configuration

- Script parseability, typed interfaces, resource paths, UIDs, node paths, nullable access, and Autoload order.
- Signal declaration, connection owner, disconnect behavior, and duplicate prevention.
- Scene ownership, instance count, freeing, re-entry, and cross-scene access.
- Configuration generator/validator, stable IDs, foreign keys, types, and malformed values.

### Automated Godot checks

Use `"$GODOT_BIN"` in generated commands. Record `--version`, command, exit code, and relevant output. An older engine may support analysis but cannot certify 4.7 compatibility.

If any required Godot check is blocked:

```yaml
delivery_status: verification_blocked
```

Do not change it to `complete` until the check passes.

### Scene and editor checks

- First load creates one correct instance.
- Exit stops input and callbacks.
- Unload frees phase-owned nodes.
- Re-entry restores or resets state exactly once.
- Repeated transition requests are deterministic.
- Signals, timers, and subscriptions do not multiply.
- Animations, focus, input capture, and transition targets remain valid.
- Output contains no new parser, orphan-node, invalid-instance, or missing-resource errors.

### Deterministic scope check

Run:

```bash
python3 .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py \
  check docs/development_tasks/TASK-NNN_short-name
```

The check covers committed changes since the approved baseline, staged changes, unstaged changes, untracked files, and pre-existing dirty files. A pre-existing file is ignored only while its captured status and fingerprint remain unchanged.

## Reports and state

`IMPLEMENTATION_REPORT.md` records Step, design decision, AI work, student work, changed files, interface changes, and deviations.

`VERIFICATION_REPORT.md` records command/manual path, engine version, expected result, actual result, pass/fail/blocked, and evidence.

`TASK_STATE.json` records current Step/checkpoint, the exact next action and artifact to open, implementation baseline, last verified commit, integration baseline, per-Step delivery/verification/participation, capability decisions, and four independent statuses.

`LEARNING_STATE.json` and `LEARNING_RECORD.md` record concepts introduced, student explanations, editor operations, verification participation, questions, unresolved concepts, assistance level, and evidence. Do not add teacher recommendations.

`INTEGRATION_HANDOFF.md` records the implemented contract, not the planned contract. Keep known limitations and pending participation explicit.

## Defect-first review

Use the available code-review capability, or perform the same review locally. Findings lead, ordered P0-P3 with narrow file/line references.

Check at least:

- Behavior and acceptance criteria.
- Stable IDs, configuration contracts, deterministic selection, and save compatibility.
- Node lifecycle, duplicate signals/timers, invalid access after free, and re-entry.
- Cross-task ownership violations and multiple active tasks editing a shared file.
- Unregistered public interface or shared-state changes.
- Main-scene accumulation and unapproved top-level restructuring.
- Deep cross-feature NodePath access and child-to-sibling control.
- Duplicate Autoload or state ownership.
- Signal payload, connection lifetime, and lifecycle-contract consistency.
- Integration handoff accuracy and verification against the integration baseline.
- Missing, ineffective, or version-mismatched tests.
- Learning claims without observed student evidence.
- Unrelated formatting, resource reserialization, generated churn, or refactors.

AI writing core code under `guided_co_development` is expected and is not an ownership violation.

Fix all in-scope P0/P1/P2 findings, rerun affected checks, update reports, and review the final diff again. Propose separate work for out-of-scope findings.

## Completion and handoff

Delivery can become `complete` when all approved behavior and required checks pass and review has no unresolved in-scope P0/P1/P2 findings.

Learning may remain `participation_pending` or `partially_demonstrated`. Handoff may remain `pending`. Report these independently.

Set `handoff_status=ready` only when the handoff document matches actual interfaces and integration checks pass. Set `integrated` only after re-verification on the recorded integration baseline.
