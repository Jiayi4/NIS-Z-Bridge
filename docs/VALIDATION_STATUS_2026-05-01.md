# Validation Status - 2026-05-01

## Summary

The current shared-folder bridge is working end-to-end from HERA to NIS for the tested fixed-slot commands.

Verified on May 1, 2026:

- `GET_Z` from HERA succeeded and returned a Z value.
- `MOVE_REL 1.000000` from HERA succeeded.
- A follow-up `GET_Z` reflected the updated Z position.

Example successful HERA output:

```text
NIS Z GET_Z requested; waiting for NIS bridge response...
NIS Z GET_Z: 5611.450 um
NIS Z: sending MOVE_REL +1.000000; waiting for NIS macro response...
NIS Z after MOVE_REL: 5612.450 um
```

## What Was Fixed

The working path now includes:

- shared `commands/<id>.txt` forwarding into fixed local slot files on the NIS PC
- hotkey-triggered rerun support for the NIS macro
- response publishing back to shared `responses/<same_id>.txt`
- response normalization so HERA receives plain-text values even when the local NIS macro writes UTF-16-style text
- orphan slot recovery for stale local command and response artifacts

## Current Stable Limitation

The bridge is still intentionally limited to the fixed commands documented in the repo.

This was confirmed by a HERA-side failure when trying an unsupported command:

```text
NIS Z: sending MOVE_REL +10.000000; waiting for NIS macro response...
NIS Z MOVE_REL +10.000000 failed: Stable shared-folder bridge only supports Step 1.000000 for Move + and Move
```

The currently validated shared-folder interface remains:

- `GET_Z`
- `MOVE_REL 1.000000`
- `MOVE_REL -1.000000`
- `MOVE_ABS 4100.000000 4050.000000 7000.000000`
- `MOVE_ABS 4200.000000 4000.000000 8100.000000`
- `STOP`

## Timing Note

During debugging, a timing issue was observed: HERA can time out if the NIS macro is not rerun after the local slot file appears. Once the macro is triggered at the right time, the bridge completes successfully.

## Suggested Next Step

If needed, the next improvement is to extend the bridge beyond fixed-slot commands so HERA can request arbitrary relative moves instead of only the validated `+1.000000` and `-1.000000` steps.
