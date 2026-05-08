# AGENTS.md

This repository is the NIS-PC side of the Nikon Z bridge. Future contributors and coding agents should optimize for reliability and local reproducibility over cleverness.

## Mission

Keep the bridge stable enough that a microscope operator can:

- start the Python sync script
- load one macro in NIS-Elements
- optionally run the hotkey runner
- send a fixed shared-folder command
- get back a shared response without hand-editing files

## Current Architecture

- `nis_z_sync_shared_to_local.py`
  Watches the shared NAS folder, maps supported commands into fixed local slot files, and publishes local responses back to the shared `responses\` folder.
- `nis_z_local_text_bridge_watcher.mac`
  Runs inside NIS-Elements, watches only local fixed slot files, and calls Nikon stage APIs.
- `nis_z_macro_hotkey_runner.ps1`
  Watches local command files and presses `F4` in NIS-Elements so the macro runs once.
- `test_get_z.ps1`
  Sends a shared `GET_Z` request and waits for the shared response.
- `check_bridge_status.ps1`
  Prints process, file, and log state for quick debugging.

## Rules For Changes

- Keep the NIS macro local-only. Do not make it read or write the shared UNC path directly.
- Prefer fixed command slots over dynamic parsing inside the macro unless a new dynamic path is proven stable in live tests.
- Preserve the simplest working path. Add diagnostics in separate files rather than rewriting the command flow.
- Treat the macro environment as fragile. Small, linear code is safer than generic abstractions.
- Do not assume saving a `.mac` file means NIS is using the new version. The operator must reload it inside NIS-Elements.

## Known Operational Facts

- The fixed-slot bridge works end-to-end for `GET_Z`, `MOVE_REL 1.000000`, `MOVE_REL -1.000000`, two fixed `MOVE_ABS` commands, and `STOP`.
- The generalized `MOVE_REL <dz>` path using one dynamic local file has not been reliable.
- The sync script accepts both decimal and integer `OK` responses such as `OK 56.000000` and `OK 56`.
- A bridge response can still return the wrong Z number even when the transport path succeeded. One observed `GET_Z` response was `OK 56` while the operator reported the real Z axis was `5698.200`.

## Debugging Order

Always debug one layer at a time:

1. Macro only:
   Create `commands\current_getz.txt`, press `F4`, inspect local `responses\current_getz_response.txt`.
2. Sync plus manual macro run:
   Run the Python sync script, send a shared command, and press `F4` yourself when the local command appears.
3. Sync plus hotkey runner:
   Only after the manual `F4` path works should the hotkey runner be part of the test.
4. Full end-to-end test:
   Use `test_get_z.ps1` and verify the shared response file appears.

## Practical Guidance

- Use `check_bridge_status.ps1` before a test, during a test, and immediately after a timeout.
- When changing the macro, ask for a local macro-only proof before diagnosing sync behavior.
- Be conservative about pushing speculative macro API changes. Document uncertainty in `README.md` when the bridge path works but the stage value appears wrong.
