# Audit And Scope Selection

## Evidence states

Classify each relevant capability as one of:

| State | Required evidence |
|---|---|
| Implemented and verified | Current executable or precise manual verification demonstrates the behavior |
| Implemented but unverified | Code and wiring appear complete, but current verification is absent |
| Partially integrated | Some layers exist, but the runtime path is incomplete |
| Code exists but is not connected | Files exist without confirmed scene, signal, state, or entry-point wiring |
| Resource/configuration only | Data or scenes exist without runtime behavior |
| Planned only | Described but not implemented |
| Missing | Required behavior and supporting implementation are absent |
| Blocked | A concrete version, environment, permission, or dependency prevents verification |

File names, comments, nodes, and imports are evidence, not proof.

## Audit procedure

1. Read product scope, frozen decisions, exclusions, and acceptance criteria.
2. Inventory configuration manifests, schemas, stable IDs, validators, and generated outputs.
3. Inspect `project.godot`: engine features, main scene, Autoloads, plugins, and input actions.
4. Map major systems by scripts, scenes, resources, signals, public interfaces, and state ownership.
5. Inventory the main scene and large branches: direct NodePaths, animation tracks, transitions, and cross-branch access.
6. Classify scenes as always resident, phase scoped, transient, pooled, or data-only.
7. Trace actual configuration-loading paths and distinguish active and legacy pipelines.
8. Inventory tests and runners; distinguish addon checks from gameplay checks.
9. Inspect Git commit, staged, unstaged, and untracked state.
10. Resolve and run the Godot executable's `--version` using the workflow order.
11. Record behavior-comparison availability only when explicitly supplied or already recorded. Do not search unrelated directories.
12. Write concrete paths, commands, confidence, and blockers. Mark inference explicitly.

## Audit freshness

`PROJECT_STATUS_AUDIT.md` records:

```yaml
audited_commit:
environment_checked_at:
engine_executable_source:
engine_version_detected:
audit_invalidation_triggers:
```

Default invalidation triggers include changes to product scope, configuration schema, main scene, Autoload list, public interfaces, dependencies, engine version, or the selected feature's owned files.

The audit also contains:

- System inventory and plan-to-runtime status matrix.
- Configuration integration status.
- Scene-tree, lifecycle, state-owner, and transition risks.
- Test and verification status.
- Behavior-comparison boundary and unresolved observations, when applicable.
- Recommended next three bounded tasks, ordered by dependency and learning value.

## Scope selection

Prefer a task that:

- Produces one observable, independently verifiable behavior.
- Has explicit inputs, outputs, dependencies, ownership, and failure behavior.
- Establishes a needed shared contract before dependent UI or content work.
- Can be understood from at most two main domain modules.
- Uses 3-7 Steps and roughly eight or fewer production files as a soft limit.
- Avoids save migration, broad scene rewrites, and unrelated UI work.
- Teaches a coherent concept and supports three meaningful participation checkpoints.
- Defines a clean integration contract for another student's feature.

Split a candidate when it combines multiple player loops, changes several state owners, introduces multiple services, or simultaneously touches content loading, shop, inventory, crafting, combat, saves, and UI.

Do not hide scene extraction inside an ordinary feature. Propose a dedicated migration with dependency inventory, rollback, lifecycle checks, and separate approval.

Selection order:

1. Shared data contract or validator needed by later work.
2. Pure domain behavior with scene-independent tests.
3. One feature scene using an established domain contract.
4. Main-scene integration after provided and consumed interfaces are stable.

## Team ownership check

Before proposing a task, inspect active task manifests for overlap:

- A shared scene or file has only one active owner.
- Changes to `project.godot`, Autoloads, main scenes, save schema, event bus, and shared configuration are explicitly registered.
- Public interface changes name all known consumers and require renewed approval.
- Conflict hotspots are listed even when overlap is expected only during integration.

Do not solve ownership conflict by refactoring another task's system. Split main-scene wiring into a later integration task when necessary.

## Scope proposal

`SCOPE_PROPOSAL.md` includes:

- Selected behavior and why it is the next bounded dependency.
- `development_strategy`, `participation_mode`, and `execution_mode` with rationale.
- Feature owner, owned systems/files, dependencies, provided interfaces, and conflict hotspots.
- Student learning value and the three participation checkpoints.
- Scene architecture impact and exact file estimate.
- Excluded systems, risk, blockers, and approval method.
- Behavior evidence boundary and deliberate differences when applicable.

## Task index

`TASK_INDEX.md` lists task ID, spec version, title, approval, delivery, learning, handoff, owner, dependencies, and task path. Do not collapse these into one status.

## Version and migration rules

Any change to behavior, acceptance criteria, allowlist, public interface, ownership, dependency, scene architecture, or required check increments `task_spec_version` and sets:

```yaml
approval_status: superseded
delivery_status: proposed
```

Legacy tasks follow this policy:

- Unapproved: migrate or regenerate.
- Approved but unstarted: migrate and renew approval.
- In progress: produce a migration proposal; do not mutate silently.
- Complete: retain as history.
