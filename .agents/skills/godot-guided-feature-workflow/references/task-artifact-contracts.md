# Task Artifact Contracts

## Package invariants

Every schema-v2 task package contains:

```text
TASK_MANIFEST.json       Immutable approved contract; change by versioning
TASK_STATE.json          Mutable execution, approval, verification, and capability state
SCOPE_PROPOSAL.md        Human-readable scope and approval summary
DEVELOPMENT_PROMPT.md    Self-contained implementation instructions
LEARNING_RECORD.md       Human-readable learning activity and evidence
LEARNING_STATE.json      Machine-readable objective learning evidence
INTEGRATION_HANDOFF.md   Team-facing feature interface and merge guide
BEHAVIOR_SPEC.md         Required only for behavior_guided or hybrid
```

Implementation creates `IMPLEMENTATION_REPORT.md`, `VERIFICATION_REPORT.md`, and `CODE_REVIEW.md` when work begins.

Do not place mutable progress in the manifest. The manifest's four status fields are the generation/approval snapshot; after approval, `TASK_STATE.json` owns current delivery, learning, and handoff progress. A manifest change that affects scope, interfaces, ownership, scene architecture, acceptance criteria, or checks creates a new `task_spec_version` and requires renewed approval.

## Manifest schema version 2

Use valid JSON. This abbreviated example shows required keys; fill every value with task-specific content.

```json
{
  "manifest_schema_version": 2,
  "generated_by_skill_version": "2.0.0",
  "task_id": "TASK-002",
  "task_spec_version": 1,
  "slug": "shop-offer-generation",
  "title": "商店候选生成闭环",
  "engine_version": "4.7",
  "development_strategy": "plan_driven",
  "participation_mode": "guided_co_development",
  "execution_mode": "teaching",
  "approval_status": "awaiting",
  "delivery_status": "proposed",
  "learning_status": "not_started",
  "handoff_status": "not_started",
  "baseline_commit": "<git-sha>",
  "objective": "<one bounded observable behavior>",
  "audit_freshness": {
    "audited_commit": "<git-sha>",
    "environment_checked_at": "<ISO-8601>",
    "engine_executable_source": "GODOT_4_7_BIN|GODOT_BIN|PATH|common_path|user_supplied|unavailable",
    "engine_version_detected": "4.7.x or unavailable",
    "audit_invalidation_triggers": []
  },
  "feature_ownership": {
    "owner_id": "student-01",
    "owned_systems": [],
    "owned_scenes": [],
    "owned_scripts": [],
    "owned_config_tables": []
  },
  "integration_contract": {
    "depends_on_tasks": [],
    "consumed_interfaces": [],
    "provided_interfaces": [],
    "emitted_signals": [],
    "received_signals": [],
    "shared_state": [],
    "registered_shared_changes": [],
    "conflict_hotspots": [],
    "required_integration_checks": []
  },
  "allowed_existing_files": [],
  "allowed_new_files": [],
  "forbidden_systems": [],
  "steps": [
    {
      "step_id": "step-01",
      "title": "<observable slice>",
      "behavior": "<input, transition, output, failure>",
      "main_concept": "<one concept>",
      "files": [],
      "automated_checks": [],
      "manual_checks": []
    }
  ],
  "participation_checkpoints": [
    {
      "checkpoint_id": "orientation",
      "type": "orientation",
      "required": true,
      "evidence_types": ["project_navigation", "concept_explanation"]
    },
    {
      "checkpoint_id": "godot-inspection",
      "type": "inspection",
      "required": true,
      "evidence_types": ["editor_operation", "scene_tree_inspection"]
    },
    {
      "checkpoint_id": "verification-handoff",
      "type": "verification_handoff",
      "required": true,
      "evidence_types": ["result_interpretation"]
    }
  ],
  "learning_contract": {
    "objectives": [],
    "concepts": [],
    "required_evidence_types": [],
    "required_student_outcomes": [
      "pre_implementation_orientation",
      "godot_inspection_or_action",
      "verification_participation",
      "input_output_dependency_explanation",
      "integration_handoff_confirmation"
    ]
  },
  "scene_architecture": {
    "architecture_change": false,
    "entry_scene": "res://<entry>.tscn",
    "lifecycle_rationale": "<why lifecycle is unaffected>",
    "current_tree": null,
    "target_tree": null,
    "ownership": [],
    "signal_contracts": [],
    "loading_policy": null,
    "state_persistence": [],
    "animation_dependencies": [],
    "lifecycle_checks": []
  },
  "required_automated_checks": [],
  "required_manual_checks": [],
  "comparison_analysis": {
    "available": false,
    "scope": "none",
    "read_only": true,
    "behavior_spec": null,
    "observed_contracts": [],
    "deliberate_differences": [],
    "unknowns": []
  },
  "scope_change_triggers": [],
  "approval": {
    "approved": false,
    "approved_version": null,
    "approved_at": null,
    "exact_user_text": null,
    "canonical_example": "确认 TASK-002 v1 进入开发"
  }
}
```

For `architecture_change=true`, `current_tree`, `target_tree`, `ownership`, `signal_contracts`, `loading_policy`, and `lifecycle_checks` must be concrete and non-empty. For `architecture_change=false`, keep the detailed fields empty and explain the entry scene and lifecycle rationale.

For `behavior_guided` or `hybrid`, set `comparison_analysis.available` to `true`, set `behavior_spec` to `BEHAVIOR_SPEC.md`, and keep that file self-contained. When comparison evidence is unavailable, set `behavior_spec` to `null`.

`registered_shared_changes` explicitly lists changes to `project.godot`, Autoloads, main scenes, save schema, event bus, or shared configuration. An empty list means the task is forbidden from changing them.

The file allowlists must include workflow artifacts that change during implementation. Put existing mutable task files such as `TASK_STATE.json`, `LEARNING_STATE.json`, `LEARNING_RECORD.md`, and `INTEGRATION_HANDOFF.md` in `allowed_existing_files`. Put implementation-time reports such as `IMPLEMENTATION_REPORT.md`, `VERIFICATION_REPORT.md`, and `CODE_REVIEW.md` in `allowed_new_files`. Do not exempt the task directory wholesale.

## Mutable task state

`TASK_STATE.json` starts with:

```json
{
  "task_id": "TASK-002",
  "task_spec_version": 1,
  "approval_status": "awaiting",
  "delivery_status": "proposed",
  "learning_status": "not_started",
  "handoff_status": "not_started",
  "current_step": null,
  "current_checkpoint": "orientation",
  "next_action": "Wait for task approval",
  "implementation_baseline": {
    "captured_at": null,
    "commit": null,
    "preexisting_changes": []
  },
  "last_verified_commit": null,
  "integration_baseline_commit": null,
  "step_state": [],
  "approval_record": {
    "approved_version": null,
    "approved_at": null,
    "exact_user_text": null
  },
  "capability_decisions": {
    "superpowers": "unknown",
    "godot_skill": "unknown",
    "code_review": "unknown"
  }
}
```

Capability decision values are `unknown`, `available`, `installed`, `declined`, `not_needed`, or `unavailable`. Persist the first explicit installation decision so later Steps do not ask repeatedly.

Each `step_state` entry records implementation status, verification status, participation status, changed files, check results, and next action. Do not infer student participation from AI output.

Before every checkpoint pause or session end, `next_action` and the active `step_state` must make resumption possible without conversation history. Record the exact student action and the file, scene, node, signal, configuration entry, or report to open, together with the completed result and any blocker. Students working at different times coordinate through ownership and `INTEGRATION_HANDOFF.md`; do not add attendance or absence state.

`current_step`, `current_checkpoint`, and every learning-evidence reference must use IDs declared by the manifest. A completed delivery records `last_verified_commit`. The implementation baseline's `captured_at` and `commit` fields are populated together and are never recaptured for the same task version.

After approval, compare current progress statuses across `TASK_STATE.json` and `LEARNING_STATE.json`, not against the manifest's initial delivery/learning/handoff snapshot. `approval_status` and the approval record still must match the approved manifest version.

## Learning state

`LEARNING_STATE.json` starts with:

```json
{
  "task_id": "TASK-002",
  "task_spec_version": 1,
  "learning_status": "not_started",
  "concepts_introduced": [],
  "concepts_explained_by_student": [],
  "editor_operations_completed": [],
  "verification_completed": [],
  "integration_contract_understood": null,
  "student_questions": [],
  "unresolved_concepts": [],
  "assistance_level": "full",
  "evidence": []
}
```

`assistance_level` is `full`, `structured`, `minimal`, or `none`. Each evidence entry records `evidence_type`, `step_id`, `checkpoint_id`, `summary`, `understanding_level`, and `observed_at`. Understanding levels are `introduced`, `recognized`, `explained`, `applied`, or `diagnosed`.

`LEARNING_RECORD.md` presents the same facts for people. Do not add a teacher-advice section.

An AI demonstration may only establish `introduced`. A student response may establish `recognized` or higher when actually observed. When editor access is unavailable, record focused artifact or result inspection using the evidence type that occurred; do not record `editor_operation` or `applied` unless the student actually performed it.

## Integration handoff

`INTEGRATION_HANDOFF.md` must contain:

1. Feature purpose and owner.
2. Runtime entry point.
3. Inputs and consumed interfaces.
4. Outputs, provided interfaces, and emitted signals.
5. State owner and persistence behavior.
6. Key scenes, scripts, configuration, and tests.
7. Integration procedure.
8. Forbidden direct access and conflict hotspots.
9. Required integration checks and latest verified baseline.
10. Known limitations and pending participation.

Do not claim `handoff_status: ready` until this document matches the implemented interfaces and required checks pass. Do not claim `integrated` until verification has run against the integration baseline.

## Approval and valid status combinations

- `approval_status=awaiting` requires `approval.approved=false` and `delivery_status=proposed`.
- `approval_status=approved` requires exact approval text and matching approved/spec versions.
- An approved manifest keeps the immutable delivery snapshot at `approved`; later delivery progress belongs to `TASK_STATE.json`.
- `approval_status=superseded` cannot have `delivery_status=complete` for the superseded version.
- `delivery_status=verification_blocked` is required when any mandatory Godot check is blocked.
- `delivery_status=complete` may coexist with pending learning or handoff.
- `delivery_status=complete` requires `last_verified_commit`.
- `handoff_status=ready` requires `delivery_status=complete`.
- `handoff_status=integrated` requires `delivery_status=complete` and a recorded integration baseline.
