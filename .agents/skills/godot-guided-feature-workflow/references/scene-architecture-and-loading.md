# Scene Architecture And Loading

## Purpose

Use this gate before generating a task that touches a scene, UI flow, gameplay phase, transition, node lifecycle, or runtime state connected to scene nodes. The goal is not to force a universal scene pattern. It is to make ownership, lifetime, interfaces, and loading behavior reviewable before implementation.

Every task records one of these decisions:

- `architecture_change: false`: the task is scene independent or preserves the existing tree and lifecycle. Record the runtime entry scene and a concrete explanation of why node ownership, lifetime, loading, signals, state persistence, and animation paths are unaffected. A bare `no change` is not enough.
- `architecture_change: true`: the task changes scene composition, ownership, loading, unloading, or cross-scene contracts and needs the complete design below.

For `architecture_change=false`, keep the detailed architecture fields empty. For `architecture_change=true`, provide current and target trees, responsibility and lifecycle ownership, signal/public interfaces, loading policy, state persistence, animation dependencies, and lifecycle checks. The manifest validator enforces this distinction.

## Architecture rules

1. Do not keep expanding a top-level main scene with complete screens or gameplay phases.
2. Give each major phase one independently owned scene when migration is justified and approved.
3. Store runtime data that must survive scene destruction outside phase-scoped scene nodes. Scene nodes render, collect input, and coordinate local behavior; they are not the only source of truth for persistent run state.
4. Child scenes emit intent or result signals upward. The owning coordinator decides whether to load, unload, or switch sibling scenes.
5. Avoid deep cross-scene `NodePath` access. Expose stable methods, properties, signals, groups, or scene-unique nodes within one ownership boundary.
6. Choose dynamic loading from lifecycle, memory, startup cost, and measured frame impact. Do not make threaded loading mandatory without evidence.
7. Treat extraction of an existing scene branch as a dedicated migration task with explicit approval.
8. Do not incidentally restructure the top-level scene while implementing an unrelated feature.
9. New Autoloads are not a default scene-management solution. They require an approved ownership need and task scope.
10. Prefer a separately owned feature scene over adding another complete branch beneath the main scene.
11. Main-scene wiring may be a separate integration Step or integration task. A feature can expose a verified scene and public contract without taking ownership of another task's main scene.
12. Shared files have one active task owner at a time. Do not let two feature tasks concurrently edit the same main scene, Autoload registration, event bus, save schema, or shared configuration file.
13. Register every planned change to `project.godot`, Autoloads, the configured main scene, save schema, event bus, or shared configuration in `integration_contract.registered_shared_changes`. An empty list forbids those changes.

## Target composition

Use this as a decision aid, not a mandatory rename:

```text
AppRoot
|-- WorldEnvironment
|-- SceneHost
|   `-- ActivePhase
|-- GlobalUI
|-- TransitionLayer
`-- DebugLayer
```

- `AppRoot` owns application-level orchestration and does not contain every phase's internal nodes.
- `SceneHost` owns the currently active phase instance.
- `GlobalUI` contains UI that truly survives phase changes. Phase-specific UI belongs to its phase.
- `TransitionLayer` owns fades, blockers, and transition progress that must outlive the departing phase.
- `DebugLayer` is optional and must not own game rules.

## Scene classification

Classify every relevant scene or node before choosing a loading policy:

| Classification | Lifetime | Typical examples | Default handling |
|---|---|---|---|
| Always resident | Whole application or run | Root coordinator, global transition layer | Instantiate once; avoid phase-owned references. |
| Phase scoped | One shop, combat, map, or result phase | Shop screen, combat arena | Instantiate on phase entry; release on exit after state transfer. |
| Transient | Short interaction | Popup, tooltip, effect | Instantiate on demand; release when complete. |
| Pooled | Repeated, high-frequency object | Projectiles, damage numbers | Reuse only when profiling or churn justifies the complexity. |
| Data/resource | Independent of scene tree | Item definitions, encounter templates | Load as immutable definitions; create separate mutable runtime state. |

## Required design artifacts

### Current and proposed trees

Show only the branches relevant to the task, but include:

- Root ownership and attached scripts.
- Instanced scenes versus locally owned nodes.
- Unique names and direct paths relied on by code.
- Animation tracks whose paths cross a proposed boundary.
- Signals connected in the editor or code.
- Nodes moved between owners during transitions.

The proposed tree must explain every added, removed, moved, dynamically instanced, or persistent node.

### Responsibility and lifecycle table

Use a table containing:

| Scene/root | Classification | Owner | Created by | Ready/activation point | Exit/free point | Re-entry policy | State retained by |
|---|---|---|---|---|---|---|---|

A scene must have one clear lifecycle owner. Code outside that owner may request behavior through the public contract but must not free or replace the scene directly.

### Runtime-state ownership

For each mutable state object, decide:

- Does it survive phase changes?
- Is it saved, run-scoped, phase-scoped, or view-only?
- Which non-view object owns the canonical value?
- How is state injected into a new scene instance?
- How are results extracted before the old scene is released?
- What prevents source configuration resources from being mutated?

Do not preserve nodes merely to preserve data. Preserve or serialize the data contract and recreate the view when appropriate.

### Signal and public-interface contract

Record for every cross-boundary interaction:

| Signal/method | Declared by | Called or connected by | Payload | Valid lifetime | Duplicate prevention | Disconnect owner |
|---|---|---|---|---|---|---|

Prefer upward signals and explicit dependency injection. A child scene must not locate a sibling through `/root`, a long relative path, or assumptions about a main scene's descendants.

Do not expose deep cross-feature `NodePath` values as an integration interface. If another feature needs access, expose a stable method, signal, Resource/data contract, group with documented membership, or coordinator-owned dependency instead.

### Animation and transition dependencies

Inventory:

- `AnimationPlayer` track paths.
- AnimationTree parameters and referenced nodes.
- Tween targets and callbacks.
- Call-method tracks and signal callbacks.
- Transition blockers, input capture, and visibility order.

When a node moves across a scene boundary, update or replace these dependencies in the approved migration task and verify every affected animation. Do not rely on path replacement alone as proof.

## Loading policy

Choose the simplest policy that satisfies the lifecycle:

| Policy | Use when | Required checks |
|---|---|---|
| `preload` + instantiate | Small, frequently used, fixed dependency | Parse/load success, one instance, correct owner, clean release. |
| Synchronous `load` | Optional or infrequent content with acceptable load time | Missing-resource failure, visible fallback, repeated request behavior. |
| Threaded load | Measured load stalls justify asynchronous work | Progress, cancellation, failure, stale request, transition lock, re-entry. |
| Keep resident/cache | Re-entry cost is proven and memory is acceptable | Reset contract, hidden input, stale state, memory ownership. |
| Object pool | High-frequency allocation is measured as a problem | Reset completeness, active/inactive ownership, signal cleanup. |

Document the measurement or lifecycle reason. Do not introduce a loader service, cache, pool, or Autoload only because it may be useful later.

## Existing coupled-scene migration

When a current main scene contains multiple phases with direct paths, animation tracks, shared nodes, or moved nodes:

1. Inventory all code paths, signals, editor connections, animation tracks, and state transfers touching the branch.
2. Freeze the desired behavior and write repeatable before-change checks.
3. Define the new owner and public contract without changing behavior.
4. Migrate one phase boundary in a dedicated task.
5. Add load, exit, and re-entry checks before removing old nodes or paths.
6. Verify transitions, focus, input capture, shared UI, and runtime state.
7. Remove obsolete paths only after all callers and animation tracks are accounted for.

If the inventory cannot fit a bounded student task, split it into contract preparation and scene migration tasks. Ordinary feature work remains on the current architecture until the migration is approved and complete.

## Shared ownership and integration

Before approving a scene-affecting task:

1. Name the task owner for every changed scene, script, configuration table, and shared registration.
2. Confirm that no other active task owns those files or public interfaces.
3. Keep feature-internal nodes and scripts inside the feature scene's ownership boundary.
4. Treat edits to the main scene, `project.godot`, Autoloads, event buses, save schema, and shared configuration as explicit integration work.
5. Record conflict hotspots and the exact integration checks that must be rerun after merge.
6. If feature implementation and main-scene wiring have different owners, expose and verify the feature contract first, then perform wiring in the separately approved integration scope.

Do not resolve a merge conflict by moving nodes, changing public signal payloads, or refactoring another feature's scene without revising the task contract.

## Verification contract

For scene-affecting tasks, acceptance criteria must cover:

- First load produces one correct instance.
- Exit prevents further input and callbacks from the departing scene.
- Unload frees phase-owned nodes without invalid access.
- Re-entry creates or restores the intended state exactly once.
- Rapid repeated transition requests have deterministic behavior.
- Signal connections and timers do not multiply after re-entry.
- Persistent state survives according to its contract; local state resets according to its contract.
- Missing or failed resource loads leave a usable state and actionable error.
- Animation, transition, focus, and input behavior remain correct.
- Godot output contains no new errors, orphan-node warnings, or invalid-instance access.

Use headless tests for ownership and lifecycle contracts where possible, then perform the shortest Godot 4.7 editor path for visual transitions and input behavior. If 4.7 is unavailable, mark those checks blocked rather than passing them with an older engine.

After merging or wiring the feature, record the integration baseline commit and rerun the required lifecycle, signal, configuration, and editor checks against that commit. Prior feature-branch verification does not prove the integrated scene tree is valid.

## Adapter selection

Load project-local helper Skills only when relevant:

- `godot-nodes-scenes`: tree composition, instancing, node access, and freeing.
- `godot-signals-groups`: signal contracts, connection lifetime, and groups.
- `godot-resources`: immutable definitions and runtime-state separation.
- `godot-animation`: animation and transition dependencies.
- `godot-gdscript-headless-testing`: lifecycle-focused headless verification.

These adapters do not authorize scene changes or expand the task allowlist.
