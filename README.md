# PokeDinner-a-Eglantine-Fork upstream mirror

This repository is maintained as an automated mirror of [Franseven/PokeDinner-a-Eglantine-Fork](https://git.eden-emu.dev/Franseven/PokeDinner-a-Eglantine-Fork) (`master`).

The workflow `.github/workflows/auto-sync-release.yml` checks upstream every 10 minutes and can be run manually. When the upstream commit changes, it mirrors the upstream source to `main`, builds Windows x64 and Linux x64 packages, and publishes a GitHub pre-release **only if all builds succeed**.

The upstream source uses GPL-3.0-or-later; license and attribution are retained when the mirror populates. Source is not modified beyond the auto-sync workflow and its status file.

Note: GitHub schedule execution is best effort and may be delayed. The full upstream source will replace this bootstrap README during the first sync.
