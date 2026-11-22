# Home Assistant — BILRESA bathroom dimming (ZHA)

Brief record of the **IKEA BILRESA scroll-wheel** remote paired via **ZHA** to control the bathroom light.

## Goal

- **Scroll wheel:** brightness on the bathroom light
- **ON button (short):** toggle `light.bathroom_light`
- **OFF button:** blueprint default (turns light off) until custom actions are added

## What was deployed (2026-11-22)

| Item | Detail |
|------|--------|
| Blueprint | [IKEA E2490 BILRESA Scroll Wheel (ZHA)](https://gist.github.com/tlux/57ebbb571fa1e7c9b6665734021d0e43) (tlux) |
| Blueprint path in HA | `gist.githubusercontent.com/ikea-e2490-bilresa-scroll-wheel.yaml` |
| Automation | `automation.bathroom_bilresa_bathroom_light` — *Bathroom Bilresa → bathroom light* |
| Remote device | Bathroom Bilresa Remote — `b813beaedd660a7070cb6aef823f9950` |
| Light | `light.bathroom_light` — bulb device `855ba59fc61cb18393d5a2d21f89254c` |

**Not used:** OSAZEE “Ultimate” Bilresa blueprint (Matter dual-button only), Vituhlos Matter integration, Matter scroll-wheel blueprints.

## Blueprint inputs (summary)

- `controller_device`: Bathroom Bilresa Remote (ZHA)
- `scroll_target`: `light.bathroom_light`
- `scroll_mode`: `brightness`
- `button_on_short`: `light.toggle` on `light.bathroom_light`
- `button_off_short`: empty (default OFF behavior still applies)

## Status / follow-ups

- **ON / OFF:** working as expected (2026-11-22).
- **Scroll dimming:** usable but felt **slow**; more testing planned. If it stays laggy, consider **[ZHA Smooth Wheel + Instant On/Off](https://gist.github.com/blakenberry/ef329b12cae310a08c11cdd4b7418b0d)** (disable this automation first — one blueprint per remote).

## Verify

1. **Settings → Automations** → traces on `automation.bathroom_bilresa_bathroom_light`
2. **Developer tools → Events** → `zha_event` while pressing / scrolling
3. Light must not be `unavailable` for dimming tests

## Re-import blueprint

Settings → Automations & scenes → Blueprints → *IKEA E2490 BILRESA Scroll Wheel (ZHA)* → re-import from the gist raw URL if tlux publishes updates.
