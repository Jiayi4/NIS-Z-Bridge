# NIS Z Bridge

This folder is the NIS-PC side of the Nikon Z bridge.

The bridge is split into two parts:

- `nis_z_sync_shared_to_local.py`
  A Windows Python script that watches the shared NAS folder, maps supported shared commands into local slot files, and publishes local responses back to the shared `responses\` folder.
- `nis_z_local_text_bridge_watcher.mac`
  A NIS macro that only touches local paths under `E:\Jiayi\NISZBridge` and calls Nikon stage APIs.

This separation is intentional. NIS should not read from or write to the UNC path directly.

## Current Status

This README reflects the real observed behavior from microscope testing on May 1, 2026.

Confirmed to work end-to-end:

- `GET_Z`
- `MOVE_REL 1.000000`
- `MOVE_REL -1.000000`
- `MOVE_ABS 4100.000000 4050.000000 7000.000000`
- `MOVE_ABS 4200.000000 4000.000000 8100.000000`
- `STOP`

Confirmed not reliable yet:

- generalized `MOVE_REL <dz>` using one local `current_move_rel.txt` file
- dynamic reading of the relative step value inside the NIS macro

Observed failure mode for the experimental generalized move path:

- HERA can send the request
- the Python bridge can forward it to the NIS PC
- the NIS macro can start
- the macro has returned `ERROR ReadFile failed for MOVE_REL`
- when the command stays pending, the hotkey runner may retrigger F4 multiple times because it only sees that the slot file still exists

So the stable shared-folder interface is still the fixed-command interface listed above.

## Folder Layout On The NIS PC

Main local root:

`E:\Jiayi\NISZBridge`

Local folders:

- `commands\`
  Local command slot files consumed by the NIS macro.
- `responses\`
  Local response files produced by the NIS macro.
- `processed\`
  Local archive for processed command and response files.
- `errors\`
  Local archive for failed command files.
- `state\`
  Local mapping files that let the Python sync script map a local slot back to the original shared command id.

Main files:

- [nis_z_sync_shared_to_local.py](</E:/Jiayi/NISZBridge/nis_z_sync_shared_to_local.py>)
- [nis_z_local_text_bridge_watcher.mac](</E:/Jiayi/NISZBridge/nis_z_local_text_bridge_watcher.mac>)
- [nis_z_macro_hotkey_runner.ps1](</E:/Jiayi/NISZBridge/nis_z_macro_hotkey_runner.ps1>)
- [README.md](</E:/Jiayi/NISZBridge/README.md>)
- `nis_z_sync.log`

## Shared-Folder Contract

Shared root:

`\\sti-nas1.rcp.epfl.ch\bios\bios-raw\backups\visible\cell\Jiayi_bios-raw\Z control shared`

Shared folders:

- `commands\<id>.txt`
  The other PC writes a new plain-text command file here.
- `forwarded\<id>.txt`
  After Python sync accepts a command, it moves the original shared file here as an archive.
- `responses\<id>.txt`
  After NIS produces a local response, Python sync writes the final response here using the same original `<id>`.

Important:

- New commands must be created in shared `commands\`.
- Do not edit files in `forwarded\`.
- `forwarded\` is only history, not an active queue.

## Stable Local Slot Mapping

Shared command text to local command file:

- shared `GET_Z`
  -> `commands\current_getz.txt`
- shared `MOVE_REL 1.000000`
  -> `commands\current_move_rel_p1.txt`
- shared `MOVE_REL -1.000000`
  -> `commands\current_move_rel_m1.txt`
- shared `MOVE_ABS 4100.000000 4050.000000 7000.000000`
  -> `commands\current_move_abs_4100_4050_7000.txt`
- shared `MOVE_ABS 4200.000000 4000.000000 8100.000000`
  -> `commands\current_move_abs_4200_4000_8100.txt`
- shared `STOP`
  -> `commands\current_stop.txt`

Local response files:

- `current_getz_response.txt`
- `current_move_rel_p1_response.txt`
- `current_move_rel_m1_response.txt`
- `current_move_abs_4100_4050_7000_response.txt`
- `current_move_abs_4200_4000_8100_response.txt`
- `current_stop_response.txt`

Each local response is mapped back to the original shared `<id>.txt` using `state\*.id`.

Experimental branch notes:

- a newer local experiment uses `commands\current_move_rel.txt`
- that path can receive forwarded commands from HERA
- that path is not reliable in the macro yet because the macro-side file read failed during live tests

## What The Other PC Should Do

The other PC only needs access to the shared NAS folder.

To send a command:

1. Create a new plain-text file with a unique filename ending in `.txt`.
2. Put it into:
   `\\sti-nas1.rcp.epfl.ch\bios\bios-raw\backups\visible\cell\Jiayi_bios-raw\Z control shared\commands\`
3. Write exactly one supported command line inside.

Examples:

```text
GET_Z
```

```text
MOVE_REL 1.000000
```

```text
MOVE_REL -1.000000
```

```text
MOVE_ABS 4100.000000 4050.000000 7000.000000
```

```text
MOVE_ABS 4200.000000 4000.000000 8100.000000
```

```text
STOP
```

Then wait for the result in:

`\\sti-nas1.rcp.epfl.ch\bios\bios-raw\backups\visible\cell\Jiayi_bios-raw\Z control shared\responses\<same_id>.txt`

Expected response format:

- `OK <z_um>`
- `ERROR <message>`

## What The NIS PC Operator Should Do

The NIS PC has two roles:

- keep the Python sync script running
- open NIS and run the macro when a command should be processed

### 1. Start The Python Sync Script

From Windows PowerShell on the NIS PC:

```powershell
& 'C:\Users\adminbios\AppData\Local\Programs\Python\Python312\python.exe' .\nis_z_sync_shared_to_local.py
```

Run it from:

`E:\Jiayi\NISZBridge`

The script will:

- ensure local folders and shared folders exist
- watch shared `commands\`
- map supported shared commands into local command slot files
- store the original shared command id into local `state\`
- move accepted shared commands into shared `forwarded\`
- watch local `responses\`
- publish local responses back into shared `responses\<id>.txt`
- archive published local responses into local `processed\`
- append runtime logs to `nis_z_sync.log`

### 2. Run The NIS Macro

1. Open NIS-Elements on the NIS PC.
2. Make sure NIS is connected to the microscope and stage.
3. Open [nis_z_local_text_bridge_watcher.mac](</E:/Jiayi/NISZBridge/nis_z_local_text_bridge_watcher.mac>).
4. Run the macro once to process the current local command slot.

Important:

- The macro is a single-run worker, not a continuous listener.
- One `Run` handles one currently present local command slot and then exits.
- If a new command arrives later, run the macro again.

### Optional Unattended Trigger On The NIS PC

If repeated manual clicks are the main pain point, you can trigger the single-run macro from Windows instead of trying to keep the macro itself in an infinite listener loop.

This repo includes:

- [nis_z_macro_hotkey_runner.ps1](</E:/Jiayi/NISZBridge/nis_z_macro_hotkey_runner.ps1>)

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\nis_z_macro_hotkey_runner.ps1 -WindowTitleContains "NIS" -RunHotkey "{F4}"
```

Important:

- the exact NIS window title may need adjustment
- on this setup, `F4` runs the current macro
- if a command stays stuck in a local slot, the hotkey runner may keep retriggering F4 every few seconds

To stop the hotkey runner cleanly:

```powershell
New-Item -ItemType File -Path E:\Jiayi\NISZBridge\stop_hotkey_runner.txt -Force
```

## Known Good Tests

During validation, these commands worked end-to-end from the HERA PC:

- `GET_Z` - returned the live Z position
- `MOVE_REL 1.000000` - stage moved up 1 um
- `MOVE_REL -1.000000` - stage moved down 1 um
- `MOVE_ABS 4100.000000 4050.000000 7000.000000` - returned `OK 4100`
- `MOVE_ABS 4200.000000 4000.000000 8100.000000` - verified successfully
- `STOP` - returned the current Z position

## What Did Not Work Reliably

The following behavior was observed during the generalized move experiment:

- HERA sent values such as `MOVE_REL 2.000000`
- the Python bridge forwarded them into `commands\current_move_rel.txt`
- the macro started and created trace files such as `found_current_move_rel.txt`
- the macro returned `ERROR ReadFile failed for MOVE_REL`
- no actual move result reached HERA for that path

This means the failure is inside the NIS macro before `StgMoveZ(...)` is called.

## Troubleshooting Checklist

If a new shared command stays in shared `commands\`:

- Python sync is probably not running.
- Or the local slot for that command is still busy.

If a shared command quickly moves into shared `forwarded\`:

- That is normal.
- It means Python sync accepted it and moved it into the next stage.

If the command reached local `commands\` but no shared response appears:

- Check whether the NIS macro has been run.
- Check local `responses\`, `processed\`, and `errors\`.
- If the hotkey runner is active, it may keep retriggering while the local command file remains stuck.

If a local response exists but no shared response appears:

- Check `nis_z_sync.log`
- Check whether the matching `state\*.id` file still exists

If the shared response says `ERROR ReadFile failed for MOVE_REL`:

- The command reached the NIS PC.
- The failure is inside the NIS macro, before `StgMoveZ(...)` is called.
- Reload the macro inside NIS and re-test.
- If it still fails, treat the dynamic file-read approach as unreliable in this environment.

Useful places to inspect:

- `E:\Jiayi\NISZBridge\commands`
- `E:\Jiayi\NISZBridge\responses`
- `E:\Jiayi\NISZBridge\processed`
- `E:\Jiayi\NISZBridge\errors`
- `E:\Jiayi\NISZBridge\state`
- `E:\Jiayi\NISZBridge\nis_z_sync.log`

## NIS Macro Pitfalls And Lessons Learned

Architecture pitfalls:

- Do not let the NIS macro read or write the UNC path directly.
- Keep the NIS macro local-only.
- Let Python handle shared-folder movement and shared-folder bookkeeping.

Nikon API pitfalls:

- Do not use `StgZ_GetLimits`.
- `STOP` should be treated conservatively. In this bridge it returns the current Z only; it does not forcibly interrupt a running `StgMoveZ`.

Macro language pitfalls:

- Keep the macro simple.
- Prefer a single `main()`.
- Avoid helper functions unless they are proven safe in this exact NIS environment.
- Avoid complex C-style abstractions.

Observed pain points:

- `ReadFile(...)` for command text was unreliable in this workflow.
- dynamic command parsing was fragile
- pointer-heavy string handling was fragile
- a macro that looked syntactically fine could still silently fail in the interpreter

Stable pattern that worked:

- fixed local file names
- one command family per explicit branch
- direct `ExistFile(...)` checks
- direct `WriteFile(...)`
- direct `StgGetPosZ(...)` and `StgMoveZ(...)`
- minimal string handling

## Safety Notes

- The NIS macro should only read and write `E:/Jiayi/NISZBridge/...`.
- Do not modify it to access the shared UNC path directly.
- Do not use `StgZ_GetLimits`.
- Keep validation moves small.
- Only use absolute moves whose ranges have been reviewed by the microscope operator.
