---
name: godot-guided-feature-workflow
description: Audit a Godot teaching project, select one bounded feature, design its scene and integration contracts, generate an approval-gated task, and guide AI-led implementation with meaningful student participation, verification, learning records, and defect-first review. Use for planned feature work or behavior-guided reconstruction; do not use for unrelated quick fixes or broad rewrites.
---

# Godot Guided Feature Workflow

Turn one planned Godot feature into a small, reviewable team task. AI may perform most engineering work, but the student must understand the feature boundary, inspect the implementation in Godot, participate in verification, and leave an accurate integration handoff.

## Non-negotiable gates

1. Audit the current engineering state before selecting work. Repository contents are evidence, not proof that behavior works.
2. Generate a versioned task package before changing gameplay code.
3. Stop for approval after task generation. Any unambiguous confirmation of the task ID and version is valid; record the exact user text.
4. Scope-changing edits increment `task_spec_version`, supersede prior approval, and require renewed approval.
5. Require a usable Git baseline before implementation. Do not overwrite or absorb unrelated dirty work.
6. Implement only the approved behavior, file allowlist, public interfaces, and scene ownership.
7. New Autoloads, save schema, public contracts, shared-state owners, dependencies, top-level scene changes, or meaningful scope expansion require a revised task.
8. Scene extraction and top-level scene restructuring are independent migration tasks.
9. Finish with required verification and defect-first review. Required Godot checks that cannot run set `delivery_status` to `verification_blocked`.
10. Treat a behavior-comparison project as read-only evidence. Do not copy its code, assets, text, identifiers, configuration values, or scene structure by default.
11. Generated task documents must be self-contained and usable without unstated conversations or external projects.
12. Record only observed student participation. AI implementation by itself is never learning evidence.

Prompt approval does not authorize scope expansion. Student confirmation does not replace verification.

## Independent controls

Read [learning-strategies.md](references/learning-strategies.md) before selecting the learning approach.

- `development_strategy`: `plan_driven`, `behavior_guided`, or `hybrid`.
- `participation_mode`: `guided_co_development`, `guided_practice`, or `independent_challenge`.
- `execution_mode`: `teaching` or `batch`.

Defaults:

- Use `hybrid` when an explicitly supplied behavior-comparison project is available; otherwise use `plan_driven`.
- Use `guided_co_development` for zero-experience students.
- Use `teaching` unless the user explicitly selects `batch`.

`guided_co_development` means AI performs most implementation while the student participates through project navigation, bounded design choices, Godot inspection, verification, explanation, and integration handoff. It does not require the student to hand-write core systems.

For zero-experience students, do not turn a checkpoint into an open-ended quiz. When the student first says they do not know or cannot complete the requested action, immediately demonstrate the smallest complete example, then ask the student to restate the principle or inspect one named result. If they still cannot identify it, state the correct observation, record the concept as unresolved, and continue the approved activity. Do not repeat the same unanswered question or wait indefinitely; only a real approval, scope, dependency, environment, or verification blocker stops delivery.

## Status model

Keep these dimensions independent:

```yaml
approval_status: awaiting | approved | superseded
delivery_status: proposed | approved | in_progress | implemented | verification_blocked | review | complete
learning_status: not_started | in_progress | participation_pending | partially_demonstrated | demonstrated
handoff_status: not_started | pending | ready | integrated
```

Functional work may be complete while learning or handoff remains pending. Never report release readiness while required verification is blocked.

State invariants:

- `delivery_status=complete` requires a recorded `last_verified_commit`.
- `handoff_status=ready` requires completed delivery; `integrated` additionally requires a recorded integration baseline and re-verification against it.
- `current_step`, `current_checkpoint`, and learning evidence must reference IDs declared by the approved manifest.
- The approved manifest is the immutable scope snapshot. Current delivery, learning, and handoff progress belongs in `TASK_STATE.json` and `LEARNING_STATE.json`.

## Workflow

```text
DISCOVER
-> AUDIT
-> SELECT_SCOPE_AND_STRATEGY
-> DESIGN_SCENE_AND_INTEGRATION_CONTRACTS
-> GENERATE_TASK_PACKAGE
-> VALIDATE_TASK_PACKAGE
-> WAIT_FOR_APPROVAL
-> ORIENT_STUDENT
-> CAPTURE_IMPLEMENTATION_BASELINE
-> IMPLEMENT_AND_VERIFY_STEP
-> STUDENT_INSPECTION_CHECKPOINT
-> RECORD_LEARNING_AND_STATE
-> IMPLEMENT_NEXT_STEP
-> FINAL_VERIFY
-> CODE_REVIEW
-> FIX_AND_REVERIFY
-> INTEGRATION_HANDOFF
```

### 1. Discover and audit

Read all applicable `AGENTS.md` files, then inspect product documents, configuration tables and validators, `project.godot`, main scenes, Autoloads, addons, tests, task history, and Git state. Read [audit-and-scope.md](references/audit-and-scope.md).

Resolve the Godot executable in this order:

1. `GODOT_4_7_BIN`
2. `GODOT_BIN`
3. `godot4.7` on `PATH`
4. `godot` on `PATH`
5. common platform install paths
6. ask the user

Run `--version`. Godot verification is valid only when major/minor is `4.7`. Store the resolved command in task state and use `"$GODOT_BIN"` in reusable commands; do not hardcode one machine's absolute path in generated instructions.

Record audit freshness:

```yaml
audited_commit:
environment_checked_at:
engine_executable_source:
engine_version_detected:
audit_invalidation_triggers:
```

Re-audit affected areas when the commit, configuration schema, engine, main scene, Autoload list, public interface, or task dependency changes.

### 2. Select one bounded task

Choose one independently verifiable behavior with explicit inputs, outputs, dependencies, ownership, and failure behavior. Prefer 3-7 Steps and roughly eight or fewer production files as a soft limit.

When behavior evidence is available, inspect only the selected feature. Separate observed behavior, current requirements, technical decisions, deliberate differences, and unknowns.

Define one main new concept per Step. For each new concept explain:

```text
What it is
-> Where it appears in Godot
-> Why this feature needs it
-> How it differs from a similar concept
-> What observable failure appears when it is misused
```

Explain behavior and data flow before syntax. Give exact editor navigation when useful, offer at most two design options, and recommend one.

### 3. Design scene and team integration boundaries

Read [scene-architecture-and-loading.md](references/scene-architecture-and-loading.md).

- `architecture_change=false`: record the entry scene and a short reason lifecycle is unaffected.
- `architecture_change=true`: define current and target trees, ownership, lifecycle, loading, signals, animation dependencies, state persistence, allowlists, and re-entry checks.

Also define feature ownership and integration contracts. Only one active task owns a shared scene or file at a time. Prefer feature scenes over adding branches to a main scene. Register changes to `project.godot`, Autoloads, main scenes, save schema, event bus, and shared configuration explicitly.

### 4. Generate and validate the task package

Read [task-artifact-contracts.md](references/task-artifact-contracts.md) and [development-prompt-template.md](references/development-prompt-template.md). Create:

```text
docs/development_tasks/TASK-NNN_short-name/
|-- TASK_MANIFEST.json
|-- TASK_STATE.json
|-- SCOPE_PROPOSAL.md
|-- DEVELOPMENT_PROMPT.md
|-- LEARNING_RECORD.md
|-- LEARNING_STATE.json
|-- INTEGRATION_HANDOFF.md
`-- BEHAVIOR_SPEC.md          # behavior_guided or hybrid only
```

Set `manifest_schema_version` to `2`, `generated_by_skill_version` to `2.0.0`, and begin with `approval_status: awaiting` and `delivery_status: proposed`.

Run:

```bash
python3 .agents/skills/godot-guided-feature-workflow/scripts/validate_task.py \
  docs/development_tasks/TASK-NNN_short-name
```

Report validation results and stop for approval. Do not change gameplay code.

### 5. Implement through meaningful checkpoints

Read [implementation-and-review.md](references/implementation-and-review.md). Before code changes, validate approval and capture the implementation baseline with `check_task_scope.py capture`.

Separate development Steps from student checkpoints. The default teaching flow is:

```text
Understand task and locate project structures
-> Explain one core principle and confirm a bounded choice
-> AI implements one verifiable slice
-> Student inspects scene, node, script, signal, or configuration in Godot
-> AI and student verify the result
-> Student completes a short understanding activity
-> Record learning evidence and integration interfaces
-> Continue
```

Use three meaningful checkpoints:

1. **Orientation:** purpose, affected systems/files, one concept, project location, and one bounded design choice.
2. **Inspection:** student inspects the implemented scene/node/script/signal/configuration in Godot.
3. **Verification and handoff:** student runs or interprets checks and can identify entry point, inputs, outputs, dependencies, and integration contract.

In `teaching`, stop at these checkpoints and wait for participation. Apply the beginner demonstration rule on the first blocked response, and do not pause after every function. In `batch`, continue through the approved Steps without checkpoint pauses; any learning evidence not yet observed remains `participation_pending`.

Whenever work pauses, update `TASK_STATE.json` with the exact current Step, checkpoint, completed result, next student action, and file or scene to open. On resume, use this state and the integration handoff instead of relying on conversation history. Students may work at different times; coordination depends on task ownership, declared interfaces, and verified handoff rather than shared attendance.

### 6. Verify, review, and hand off

Run task checks, configuration validation, Godot 4.7 checks, and deterministic scope checking. Then perform defect-first review of behavior, lifecycle, ownership, public interfaces, integration conflicts, stable IDs, and learning evidence.

Generate or update:

```text
IMPLEMENTATION_REPORT.md
VERIFICATION_REPORT.md
CODE_REVIEW.md
LEARNING_RECORD.md
LEARNING_STATE.json
INTEGRATION_HANDOFF.md
TASK_STATE.json
```

Reverify against the latest integration baseline before handoff. Main-scene wiring may be a separate integration Step or task. Do not resolve conflicts by refactoring another student's owned system.

## Legacy task policy

- Unapproved legacy task: migrate or regenerate before use.
- Approved but unstarted legacy task: migrate and renew approval.
- In-progress legacy task: generate a migration proposal; do not mutate it silently.
- Complete legacy task: retain as history.

The validator exits with a clear migration-required result for old schemas. Do not rewrite historical tasks merely to make validation green.

## External capability policy

Superpowers, project-local Godot Skills, and code-review capabilities are optional adapters.

- Prompt generation must work without them.
- At implementation start, inspect whether an appropriate capability is callable.
- If a requested implementation adapter is missing, ask once whether to install it. Persist the decision in `TASK_STATE.json`.
- If installation is declined, continue with the built-in workflow.
- Never install, download, enable plugins, alter global configuration, create worktrees, or spawn parallel agents without direct authorization.
- External adapters never expand the approved manifest.

Load only relevant Godot adapters:

| Adapter | Use for |
|---|---|
| `godot-nodes-scenes` | Scene composition, instancing, node lookup, ownership, and freeing. |
| `godot-signals-groups` | Signal contracts, connection ownership, groups, and duplicate-connection risks. |
| `godot-resources` | Data definitions and separation from runtime scene instances. |
| `godot-animation` | AnimationPlayer, AnimationTree, Tween, and transition dependencies. |
| `godot-gdscript-headless-testing` | Deterministic headless and lifecycle checks. |
