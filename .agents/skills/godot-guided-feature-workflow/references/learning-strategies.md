# Learning Strategies

## Independent controls

### Development strategy

| Value | Use when | Main learning value |
|---|---|---|
| `plan_driven` | Current plans, configuration, and engineering contracts define the feature | Turning requirements into maintainable Godot systems |
| `behavior_guided` | A supplied behavior-comparison project defines the target behavior | Observing, specifying, and reconstructing behavior without copying implementation |
| `hybrid` | Behavior evidence and current plans must be reconciled | Distinguishing retained behavior, deliberate differences, and current architecture decisions |

### Participation mode

| Value | AI role | Student role |
|---|---|---|
| `guided_co_development` | Performs most engineering implementation and explains decisions | Navigates the project, confirms bounded choices, inspects Godot structures, participates in verification, and completes handoff understanding |
| `guided_practice` | Implements foundations and provides bounded guidance | Performs selected editor operations, configuration edits, node setup, or small local patches |
| `independent_challenge` | Defines contracts, reviews, and assists after an attempt | Attempts the core implementation and diagnosis |

Default to `guided_co_development` for zero-experience students. Do not make core hand-coding a condition of learning in this mode.

### Execution mode

| Value | Behavior |
|---|---|
| `teaching` | Stop at meaningful student checkpoints and wait for participation |
| `batch` | Continue through approved Steps without checkpoint pauses; learning evidence not yet observed remains pending |

The three controls are independent. A task can be `hybrid + guided_co_development + teaching`.

## Student outcome

The student should become the feature owner who can explain:

- What the feature does and why it exists.
- Where its scenes, scripts, configuration, tests, and entry points live.
- Its inputs, outputs, dependencies, signals, and state owner.
- How to verify it and where to investigate failures.
- How teammates may integrate with it and what they must not access directly.

Learning is not measured by code volume. AI may write the core implementation while the student demonstrates these capabilities.

## Beginner explanation rule

For each new concept, explain in this order:

```text
What it is
-> Where it appears in Godot
-> Why the feature needs it
-> How it differs from a similar concept
-> What visible or logged failure appears when it is misused
```

Additional constraints:

- Teach one main new concept per Step.
- Define terminology on first use.
- Explain behavior and data flow before syntax.
- Give exact editor navigation when an editor action is required.
- Offer no more than two meaningful design options and recommend one.
- Do not require the student to read an entire script; identify the exact class, method, signal, property, or node to inspect.
- Increase participation gradually: navigation, scene inspection, test execution, signal tracing, configuration edits, node setup, guided patch, independent patch.

## Beginner anti-blocking rule

Do not repeatedly ask a zero-experience student to guess. At the first response that the student does not know or cannot perform the action:

1. Demonstrate the smallest complete action using exact Godot navigation, a focused artifact, or a concrete verification result.
2. Explain the visible cause-and-effect in one short pass.
3. Ask the student to restate the principle in their own words or inspect one named result from the demonstration.
4. If the student still cannot identify the result, state the correct observation, record the concept as unresolved, and continue the approved activity instead of waiting indefinitely.

The AI demonstration records at most `introduced`. A student who correctly identifies the demonstrated result may record `recognized`; use `explained`, `applied`, or `diagnosed` only when the student actually demonstrates that level. Only a real approval, scope, dependency, environment, or verification blocker stops delivery.

If a Godot editor operation is temporarily unavailable, substitute a focused inspection of the relevant `.tscn`, script, configuration entry, test result, screenshot, or captured log. Record the evidence type that actually occurred and do not claim `editor_operation` or `applied` from passive inspection. A substitution may satisfy learning continuity, but it does not bypass a required technical or Godot 4.7 verification check.

## Pause, resume, and asynchronous cooperation

Before every checkpoint pause or session end, record:

- Current Step and checkpoint IDs.
- What implementation and verification are complete.
- The exact next student action.
- The file, scene, node, signal, configuration row, or report to open.
- Any unresolved concept or technical blocker.

On resume, read `TASK_STATE.json`, `LEARNING_STATE.json`, and `INTEGRATION_HANDOFF.md`, then restate the current location and next action in one short orientation. Students may work at different times. Use ownership boundaries, declared interfaces, and verified handoffs to coordinate work; do not introduce attendance or absence handling into the task flow.

## Meaningful checkpoints

Development Steps and learning checkpoints are separate. A Step may contain one or more implementation changes but should stop only at a meaningful participation point.

### Checkpoint 1: orientation before implementation

The student should be able to identify:

- The task's player-visible purpose.
- The affected systems and exact project locations.
- One core concept.
- The recommended bounded design choice.

Accept short answers, a file-location confirmation, or selection between at most two options. Correct misconceptions before implementation.

If the student says they do not know, apply the beginner anti-blocking rule immediately.

### Checkpoint 2: Godot inspection after implementation

Guide the student to inspect at least one real artifact:

- Scene tree and node ownership.
- Script attachment and a focused method.
- Signal declaration and connection.
- Resource or configuration entry.
- Test scene or headless runner.

Record the editor path and what the student observed. Passive acknowledgement is not enough.

When editor access is unavailable, use the focused-inspection substitution and record the lower evidence level honestly.

### Checkpoint 3: verification and handoff

The student should run or interpret at least one check and identify:

- Entry point.
- Inputs and outputs.
- Dependencies and provided interfaces.
- A likely failure location.
- The integration method and forbidden direct access.

This checkpoint prepares multiple students to merge features without relying on hidden AI context.

## Evidence model

Allowed evidence types:

```text
concept_explanation
project_navigation
editor_operation
scene_tree_inspection
signal_trace
configuration_inspection
test_execution
result_interpretation
error_diagnosis
ai_diff_review
parameter_adjustment
guided_patch
independent_patch
```

Understanding levels:

```text
introduced | recognized | explained | applied | diagnosed
```

AI implementation alone is not evidence. Record only actions or explanations actually supplied by the student.

`LEARNING_STATE.json` uses objective fields:

```yaml
concepts_introduced:
concepts_explained_by_student:
editor_operations_completed:
verification_completed:
integration_contract_understood:
student_questions:
unresolved_concepts:
assistance_level:
```

Do not add mandatory teacher advice or recommendations. Teachers can analyze the committed records separately.

## Behavior evidence safety

Treat behavior comparison as bounded, read-only evidence. Classify findings as:

- Observed behavior.
- Current requirement.
- Technical decision.
- Deliberate difference.
- Unknown.

Do not copy code, assets, text, identifiers, configuration values, or scene structure by default. The task must remain executable when the comparison project is unavailable.

For `behavior_guided` and `hybrid`, `BEHAVIOR_SPEC.md` must define preconditions, inputs, state transitions, invariants, outputs, failures, retries, edge cases, deliberate differences, unknowns, and self-contained acceptance criteria.
