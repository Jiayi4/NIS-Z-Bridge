# NIS Z Bridge Implementation Plan

This plan assumes we keep the GitHub `main` branch as the stable shared-folder baseline and develop the next features in small, testable steps.

## Phase 1: Clean baseline

Goal:

- make it obvious which files are stable and which are experimental

Steps:

1. Inventory and label the current local-only experiment files.
2. Isolate the TCP experiment from the stable shared-folder bridge.
3. Restore or preserve the stable macro safety checks before further feature work.
4. Keep the README aligned with the code that is actually considered stable.

Exit criteria:

- one clear stable path
- one clear experimental path
- no ambiguity about what is on GitHub

## Phase 2: Continuous local listener

Goal:

- investigate whether manual macro re-runs can be removed safely

Guiding constraints:

- keep the NIS side local-only
- keep a single `main()`
- keep fixed slot names
- avoid generic parsing inside the macro

Status on 2026-05-01:

- a continuous `while(1)` listener was tested locally
- the macro launch could succeed, but loop behavior was not reliable enough to treat as stable
- the current recommendation is to keep the single-run macro as the supported path unless a more reliable external trigger is found

Suggested approach if this is revisited later:

1. Start from the stable single-run macro.
2. Add a minimal loop with a conservative sleep interval.
3. Preserve the exact fixed-slot branch logic first.
4. Add a lightweight heartbeat file only if needed for operator visibility.
5. Validate that long-running macro execution is stable in NIS before any protocol changes.

Validation:

- `GET_Z`
- `MOVE_REL 1.000000`
- `MOVE_REL -1.000000`
- both validated `MOVE_ABS` cases
- `STOP`
- idle loop stability over an extended run

## Phase 3: Safer protocol generalization

Goal:

- support more Z targets without rebuilding a fragile macro parser

Recommended direction:

- keep command validation in Python
- keep NIS execution simple

Suggested design:

1. Python accepts richer commands from HERA or the shared folder.
2. Python validates range and shape of each request.
3. Python maps requests into a small local protocol that NIS can handle safely.
4. NIS reads only minimal local data, ideally one fixed file per command family.

Preferred order:

1. generalize `MOVE_REL dz` first
2. then add carefully bounded `MOVE_ABS z min max`

Validation:

- verify rejected out-of-range values return clear errors
- verify accepted values keep correct response formatting
- verify no command leaves stale slot-state files behind

## Phase 4: HERA integration

Goal:

- make HERA the user-facing command source

Suggested scope:

1. HERA writes commands to the shared folder using the stable file contract.
2. HERA waits for responses with the same command id.
3. HERA surfaces timeouts and `ERROR ...` responses clearly.
4. HERA only enables command shapes already supported by the bridge version in use.

Validation:

- test from HERA end to end against the stable bridge
- add visible handling for timeout, busy-slot, and unsupported-command cases

## Phase 5: Optional transport upgrade

Goal:

- evaluate whether TCP is worth adopting later

Recommendation:

- do not switch to TCP until the continuous local listener is stable and the HERA contract is solid

Reason:

- changing transport and macro behavior at the same time makes debugging much harder

## Immediate next actions

1. Keep the single-run macro as the stable path.
2. Re-test all currently supported commands end to end with the hardened Python bridge.
3. Clear or quarantine stale shared `commands\` backlog during testing.
4. Finish the HERA-side flow against the stable shared-folder contract.
