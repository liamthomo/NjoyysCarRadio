# Standalone Car Radio

A framework-independent FiveM vehicle radio for Qbox, ESX, and QBCore. It has no framework or audio-library dependencies and uses the official YouTube embedded player rather than downloading or extracting audio.

## Install

1. Copy the `carradio` folder into your server's resources directory.
2. Add `ensure carradio` to `server.cfg`.
3. Use OneSync so the server can validate networked vehicle entities.
4. In game, use `/carradio` while in a vehicle.

The driver can submit a YouTube video URL or stop the radio. Other players within the configured range hear the closest active car radio; volume fades with distance. Each client can set their own local volume.

## Configuration

Edit `config.lua`:

| Setting | Default | Description |
| --- | --- | --- |
| `Config.Command` | `carradio` | Chat command that opens the radio |
| `Config.MaxDistance` | `35.0` | Maximum distance at which other players hear a radio |
| `Config.MaxVolume` | `0.40` | Maximum local playback volume, from `0.0` to `1.0` |
| `Config.DistanceFalloff` | `true` | Fade volume as listeners move away |

## Playback notes

YouTube availability and embedding rules apply. Private, age-restricted, region-blocked, or non-embeddable videos will not play. Playback depends on the FiveM Chromium UI being able to load YouTube, and autoplay restrictions may prevent audio on some client setups.
