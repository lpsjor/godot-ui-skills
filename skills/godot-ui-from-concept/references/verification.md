# Verification

## Commands

Run the project's tests and a headless editor parse:

```bash
godot --headless --path . res://tests/run_tests.tscn
godot --headless --path . --editor --quit
```

Render real screenshots:

```bash
SCENE=res://scenes/home/home.tscn OUT=/tmp/home-720.png WIDTH=720 HEIGHT=1280 \
  godot --path . --rendering-driver opengl3 --resolution 720x1280 \
  -s /path/to/shot_ui.gd
```

Repeat at 320x568, 375x667, 430x932, and a tablet size such as 960x1280.

## What tests should assert

Prefer ratios and contracts over exact screenshot pixels:

- The grid has two columns and the expected parent ratio container.
- Cards are portrait and keep the intended ratio within tolerance.
- Cards fill their cells (`EXPAND_FILL`), not their minimum size.
- The gear is anchored above the banner slot.
- No visible banner placeholder exists.
- No removed nodes (intro, max-tier tile, etc.) remain.
- `NEW` appears with no run or a dead/timeout run.
- `RESUME` appears only for a `playing` run.
- Each mode's normal and hover styleboxes exist and differ where intended.
- Icon opaque-core centers are within 2px of the texture center.
- The editor parses the scene with no `SCRIPT ERROR`.

Do not test a specific font's glyph shapes or a screenshot's exact color. Those are visual review.

## State matrix

Exercise at least:

| State | Expected |
|---|---|
| No saved run | `NEW` |
| Saved run with `status == playing` | `RESUME` |
| Saved run with `status == dead` or `timeout` | `NEW` |
| Hover a mode card | That mode's hover accent, not a shared cyan |
| Press a mode card | That mode's pressed style |
| No banner | Reserved blank slot, no placeholder UI |
| Banner enabled | Native overlay occupies the slot; no UI overlap |

## Locale matrix

Render every locale the product ships. Check:

- the longest mode name;
- the status pill (`RESUME`/`NEW` translations);
- the best score line;
- title spacing;
- clipped descenders or ascenders;
- the pixel font vs the normal UI font boundary.

For a Home-only pixel font, also verify that Game and Settings still use the normal font.

## Measurement

Use a `SubViewport` with an explicit size. The headless root viewport may not match the project's design size.

```gdscript
var vp := SubViewport.new()
vp.size = Vector2i(720, 1280)
root.add_child(vp)
var scene := load("res://scenes/home/home.tscn").instantiate()
vp.add_child(scene)
scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

Print every relevant `Control`:

```text
path position size combined_minimum_size
```

Check the grid, one card in each row, the floating gear, and the banner slot.

## Visual review

A passing test suite is not UI proof. Open the actual rendered image and check:

- alignment against the concept;
- title/card spacing;
- icon visual centering, not just file centering;
- glow softness;
- text readability at phone size;
- bottom banner area and gear clearance;
- scanlines or background effects.

## When old tests fail

A layout redesign intentionally breaks tests that pin the old layout. Update them to the new contract:

- replace square-card assertions with ratio assertions;
- replace the old node paths;
- remove assertions for deleted nodes;
- add status and icon-centering tests;
- keep product rules that still apply (for example, no separate continue button).

Do not delete a test just to make it green without deciding what the new invariant is.
