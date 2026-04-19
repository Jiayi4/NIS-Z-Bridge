# NIS Z Bridge

This folder contains the NIS-PC side of the Nikon Z bridge.

## Folder layout

- `commands\`: local fixed-slot command files consumed by the NIS macro watcher
- `responses\`: local fixed-slot response files produced by the NIS macro watcher
- `processed\`: local archive for processed command/response files
- `errors\`: local archive for failed command files
- `state\`: local mapping files that let the Python sync script map a fixed slot back to the original shared command id
- `nis_z_sync_shared_to_local.py`: Windows Python sync loop between the NAS share and the local bridge folders
- `nis_z_local_text_bridge_watcher.mac`: NIS macro watcher that talks to Nikon stage APIs using only local paths
- `nis_z_sync.log`: sync log written by the Python script at runtime

## Shared-folder contract

Shared root:

`\\sti-nas1.rcp.epfl.ch\bios\bios-raw\backups\visible\cell\Jiayi_bios-raw\Z control shared`

Queues:

- `commands\<id>.txt`: written by the HERA PC
- `forwarded\<id>.txt`: shared archive after the NIS-PC sync script copies a command locally
- `responses\<id>.txt`: written by the NIS-PC sync script after the macro generates a local response

Current fixed-slot protocol:

- shared `GET_Z` -> local `commands\current_getz.txt`
- shared `MOVE_REL 1.000000` -> local `commands\current_move_rel_p1.txt`
- shared `MOVE_REL -1.000000` -> local `commands\current_move_rel_m1.txt`
- shared `MOVE_ABS 4100.000000 4050.000000 7000.000000` -> local `commands\current_move_abs_4100_4050_7000.txt`
- shared `MOVE_ABS 4200.000000 4000.000000 8100.000000` -> local `commands\current_move_abs_4200_4000_8100.txt`
- shared `STOP` -> local `commands\current_stop.txt`

Current v1 limitations:

- only the specific tested absolute commands `MOVE_ABS 4100.000000 4050.000000 7000.000000` and `MOVE_ABS 4200.000000 4000.000000 8100.000000` are forwarded in this fixed-slot version
- only one outstanding command per slot is supported

Responses are plain text:

- `OK <z_um>`
- `ERROR <message>`

## Start the sync script

Run the sync loop from Windows PowerShell on the NIS PC:

```powershell
py -3 .\nis_z_sync_shared_to_local.py
```

If `py` is unavailable, use the local Python launcher already installed on that PC.

The script will:

- ensure the local folders and shared folders exist
- map supported shared commands into fixed local command-slot filenames
- record the original shared command id in local `state\`
- move copied shared commands into shared `forwarded\`
- copy fixed local responses back into shared `responses\<id>.txt`
- move published local responses into local `processed\`
- append logs to `nis_z_sync.log`

## Start the NIS watcher

1. Open NIS-Elements on the NIS PC.
2. Open `nis_z_local_text_bridge_watcher.mac` from this folder.
3. Run the macro while NIS remains connected to the microscope/stage.
4. Stop it using the NIS macro stop/abort control when you are done.

## Safety notes

- The NIS macro only reads and writes `E:/Jiayi/NISZBridge/...`.
- Do not modify it to access the UNC share directly.
- Do not use `StgZ_GetLimits`.
- Keep relative test moves small during first validation.
