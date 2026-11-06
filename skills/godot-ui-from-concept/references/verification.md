# Verification

## Commands

Run the project's tests and a headless editor parse:

```bash
godot --headless --path . res://tests/run_tests.tscn
godot --headless --path . --editor --quit
```

Render real screenshots:

```bash
SCENE=res://path/to/screen.tscn OUT=/tmp/screen-720.png WIDTH=720 HEIGHT=1280 \
  godot --path . --rendering-driver opengl3 --resolution 720x1280 \
  -s /path/to/shot_ui.gd
```

Repeat at 320x568, 375x667, 430x932, and a tablet size such as 960x1280.

## What tests should assert

Prefer ratios and contracts over exact screenshot pixels:

- The grid has two columns and the expected parent ratio container.
- Cards are portrait and keep the intended ratio within tolerance.
- Cards fill their cells (`EXPAND_FILL`), not their minimum size.
- Floating controls are anchored above any reserved platform slot.
- No visible placeholder occupies the reserved slot.
- No removed nodes remain.
- The start label appears with no saved run or a terminal saved run.
- The resume label appears only for a resumable run.
- Each variant's normal and hover styleboxes exist and differ where intended.
- Icon opaque-core centers are within 2px of the texture center.
- The editor parses the scene with no `SCRIPT ERROR`.

Do not test a specific font's glyph shapes or a screenshot's exact color. Those are visual review.

## Persisted state is not the same as resumable state

A saved record can represent an active run, a finished run, or a stale record. Do not derive a `Continue`/`Resume` label from record existence alone.

- Read the persisted status and any terminal flags.
- Show the resumable label only for genuinely resumable states.
- Show the new/start label for missing or terminal states.
- Make the tap behavior match the label: a card labelled as new must start a new run, not restore a terminal one.
- Add a test for each state transition, including the terminal one.

This is a product-state rule, not a theme rule; keep it in the screen controller or save service, not in a visual variation.

## State matrix

Exercise at least:

| State | Expected |
|---|---|
| No saved run | Start label |
| Saved run in a resumable state | Resume label |
| Saved run in a terminal state | Start label |
| Hover a variant card | That variant's hover accent, not the base accent |
| Press a variant card | That variant's pressed style |
| Platform slot disabled | Reserved blank slot, no placeholder UI |
| Platform slot enabled | Native overlay occupies the slot; no UI overlap |

## Locale matrix

Render every locale the product ships. Check:

- the longest localized label;
- the status pill translations;
- the secondary metadata line;
- title spacing;
- clipped descenders or ascenders;
- the pixel font vs the normal UI font boundary.

For a screen-scoped pixel font, also verify that other screens still use the normal font.

## Measurement

Use a `SubViewport` with an explicit size. The headless root viewport may not match the project's design size.

```gdscript
var vp := SubViewport.new()
vp.size = Vector2i(720, 1280)
root.add_child(vp)
var scene := load("res://path/to/screen.tscn").instantiate()
vp.add_child(scene)
scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

Print every relevant `Control`:

```text
path position size combined_minimum_size
```

Check the grid, one card in each row, the floating controls, and any reserved platform slot.

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
- keep product rules that still apply (for example, a navigation rule that predates the redesign).

Do not delete a test just to make it green without deciding what the new invariant is.
