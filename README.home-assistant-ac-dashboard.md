# Home Assistant — AC dashboard button layout

Compact icon-only scene buttons on the **AC** dashboard (`dashboard-ac`), **Home** view.

## What changed

All **25** Cool / Heat / Dry / Off scene `button` cards (per-room AC scenes + `scene.all_air_off`):

| Setting | Value |
|---------|-------|
| `grid_options.columns` | `3` |
| `grid_options.rows` | `"auto"` |
| `show_name` | `false` (icons only) |

Applied via `ha_config_set_dashboard` `python_transform` on `dashboard-ac`, view index 0.

**config_hash after final change:** `feebc1529eada652` (Aug 2026)

Native `button` cards ignore `grid_options.rows` for height in many cases; combining `columns: 3`, `rows: auto`, and hiding labels produced a layout the user accepted.

## Revert

Fetch a fresh `config_hash` with `ha_config_get_dashboard` before any edit — it changes after each write.

### Restore labels only

```python
for section in config['views'][0]['sections']:
  cards = section.get('cards')
  if not isinstance(cards, list):
    continue
  for card in cards:
    if card.get('type') != 'button':
      continue
    entity = card.get('entity', '')
    if not isinstance(entity, str):
      continue
    if not ('.cool_' in entity or '.heat_' in entity or '.dry_' in entity or entity.endswith('_off')):
      continue
    card['show_name'] = True
```

### Revert grid to `rows: 1` (labels visible)

Prior hash: `1d7b9c4eb74d1f6c`. Office and East Wing Cool had `columns: 6` in addition to `rows: 1`.

```python
for section in config['views'][0]['sections']:
  cards = section.get('cards')
  if not isinstance(cards, list):
    continue
  for card in cards:
    if card.get('type') != 'button':
      continue
    entity = card.get('entity', '')
    if not isinstance(entity, str):
      continue
    if not ('.cool_' in entity or '.heat_' in entity or '.dry_' in entity or entity.endswith('_off')):
      continue
    if entity in ('scene.cool_office', 'scene.cool_east_wing'):
      card['grid_options'] = {'columns': 6, 'rows': 1}
    else:
      card['grid_options'] = {'rows': 1}
    card['show_name'] = True
```

### Full revert to original (before any height work)

- `scene.cool_living_room`: `rows: 2`
- `scene.cool_office`, `scene.cool_east_wing`: `columns: 6`, `rows: 2`
- Other Cool/Heat/Dry/Off buttons: no `grid_options`, `show_name: true`

```python
for section in config['views'][0]['sections']:
  cards = section.get('cards')
  if not isinstance(cards, list):
    continue
  for card in cards:
    if card.get('type') != 'button':
      continue
    entity = card.get('entity', '')
    if not isinstance(entity, str):
      continue
    if not ('.cool_' in entity or '.heat_' in entity or '.dry_' in entity or entity.endswith('_off')):
      continue
    if entity == 'scene.cool_living_room':
      card['grid_options'] = {'rows': 2}
    elif entity in ('scene.cool_office', 'scene.cool_east_wing'):
      card['grid_options'] = {'columns': 6, 'rows': 2}
    elif 'grid_options' in card:
      del card['grid_options']
    card['show_name'] = True
```

## Options not taken

Setting `grid_options.rows: 1` alone did not visibly shrink buttons. Switching card type to `tile` or `custom:button-card` was not pursued after the icon-only layout was accepted.
