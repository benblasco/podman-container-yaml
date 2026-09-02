# Home Assistant — STYRBAR dimming (Kitchen & Living Room)

Local blueprint forks for IKEA STYRBAR remotes on **micro.lan**. Replaces the Thomas Maxson blueprint (500 ms minimum between dim steps) with basnijholt-style millisecond tick dimming, while keeping arrow buttons mapped to non-dimmable Shelly switches.

Upstream: [basnijholt ZHA STYRBAR blueprint](https://gist.github.com/basnijholt/39205a1082f2740a930b437b12db290b)

## Why forked

- Thomas blueprint `repeat_delay` floor is **500 ms** — hold-to-dim felt sluggish.
- basnijholt imported unmodified hardcodes arrows to **color temperature** — useless on brightness-only dining/living lights and conflicts with separate kitchen/porch switch automations.
- **Fork** = copy YAML into `config/blueprints/automation/` and edit locally (imported community blueprints are read-only in HA).

Blueprint sources (also in `~/Projects/home-assistant/blueprints/automation/`):

| Remote | Blueprint file |
|--------|----------------|
| Kitchen | `kitchen_styrbar_zha_dining_kitchen_fork.yaml` |
| Living Room | `living_room_styrbar_zha_living_porch_fork.yaml` |

On HA: `/var/lib/containers/storage/volumes/homeassistant-config/_data/blueprints/automation/`

## Kitchen Styrbar

| Item | Value |
|------|-------|
| Automation | `automation.kitchen_styrbar_dining_dim_kitchen_switch_fork` |
| Remote device_id | `e3d06f36aed6ef276ef9b5508de1a27f` |
| Dimming target | `light.dining_room_lights_shelly` |
| Arrow target | `switch.kitchen_light_shelly` |
| Dimming | `tick_ms: 100`, `step_pct: 5` |

| Button | Action |
|--------|--------|
| UP/DOWN short | Dining light on / off |
| UP/DOWN hold | Dim dining light |
| Right arrow | Kitchen switch on |
| Left arrow | Kitchen switch off |

## Living Room Styrbar

| Item | Value |
|------|-------|
| Automation | `automation.living_room_styrbar_living_dim_porch_switch_fork` |
| Remote device_id | `459efb1aaf7034f8e26f2628ce51c92d` |
| Dimming target | `light.living_room_lights_shelly` |
| Arrow target | `switch.front_porch_light` |
| Dimming | `tick_ms: 100`, `step_pct: 5` |

| Button | Action |
|--------|--------|
| UP/DOWN short | Living room light on / off |
| UP/DOWN hold | Dim living room light |
| Right arrow | Front porch switch on |
| Left arrow | Front porch switch off |

## Rollback

These automations were **disabled, not deleted**. To revert: disable the fork automations and re-enable the originals.

- `automation.kitchen_styrbar_to_dining_room_light_shelly` (Thomas blueprint)
- `automation.kitchen_styrbar_right_arrow_zha_256_kitchen_shelly_on`
- `automation.living_room_styrbar_to_living_room_light_shelly` (Thomas blueprint)
- `automation.living_room_styrbar_left_and_right_arrows_to_front_porch_light_shelly`

## Tuning

Adjust `tick_ms` (try 75–150 ms) or `step_pct` in the automation blueprint inputs — no YAML edit needed for those two values.

## Options not taken

Thomas-only tuning (still 500 ms floor), unmodified basnijholt import, running basnijholt alongside separate arrow automations, or a fully custom non-blueprint automation.
