# Repo State on 2026-05-01

This note explains what is currently on GitHub versus what only exists in the local working folder `E:\Jiayi\NISZBridge`.

## GitHub / `origin/main`

Remote repository:

- `https://github.com/Jiayi4/NIS-Z-Bridge.git`

Current remote commit:

- `3e96af7` `Update README.md`

Tracked files on GitHub:

- `.gitattributes`
- `.gitignore`
- `README.md`
- `nis_z_local_text_bridge_watcher.mac`
- `nis_z_sync_shared_to_local.py`

The GitHub repository documents and ships the stable fixed-slot shared-folder bridge.

## Local checkout

Current branch:

- `main`

Local `HEAD`:

- `3e96af7`

That means local `HEAD` and `origin/main` point to the same commit. The confusion comes from local uncommitted changes and local-only experiment files.

## Local tracked files modified after the last push

These files are tracked by git and differ from GitHub right now:

- `nis_z_local_text_bridge_watcher.mac`
- `nis_z_sync_shared_to_local.py`

### Local macro changes

The current local `nis_z_local_text_bridge_watcher.mac` is back on the single-run execution model.

Notable local differences from GitHub:

- `STOP` handling is present
- the macro remains local-only and fixed-slot
- continuous-listener experiments were removed from the stable root after local testing showed they were not reliable enough

This keeps the main execution path aligned with the stable README again.

### Local sync-script changes

The current local `nis_z_sync_shared_to_local.py` still follows the fixed-slot shared-folder design, but it now includes local orphan recovery for easier testing.

Notable differences from GitHub:

- same fixed-slot command map and same overall bridge behavior
- local orphan command files are auto-archived after a timeout
- local orphan response files are auto-archived after a timeout

This makes the bridge less fragile during repeated tests.

## Local-only untracked files

These local notes are present on this computer but are not on GitHub:

- `docs/REPO_STATE.md`
- `docs/IMPLEMENTATION_PLAN.md`

## Practical interpretation

There are currently two main states to keep in mind:

1. GitHub-stable fixed-slot shared-folder bridge
2. local hardening and documentation updates on top of that bridge

## Recommended cleanup direction

1. Keep GitHub `main` as the stable shared-folder baseline.
2. Treat the single-run macro plus the hardened Python bridge as the current working path.
3. Keep continuous-listener ideas out of the stable root unless a new approach is validated.
4. Update GitHub only after the stable path is re-tested end to end.
