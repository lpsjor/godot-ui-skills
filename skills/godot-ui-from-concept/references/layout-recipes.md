# Layout recipes

## Container selection

| Need | Use | Why not the alternative |
|---|---|---|
| Outer safe padding | `MarginContainer` | Anchors alone do not reserve padding. |
| Vertical rhythm | `VBoxContainer` | Manual positions drift when fonts change. |
| One row | `HBoxContainer` | Same. |
| Repeated cards | `GridContainer` | A custom `Container` reimplements min-size and flags. |
| Fixed card block ratio | `AspectRatioContainer` | A plain `GridContainer` fills whatever height it is given. |
| Center one child at min size | `CenterContainer` | It does not make the child expand. |
| Tablet gutter | `MaxWidthContainer` or a capped `Control` | A fixed width breaks phones. |
| Floating gear/FAB | Plain `Control` + anchors | A container will lay out all Control children. |

## Aspect-locked card grid

This is the tested pattern for a 2x2 portrait-card grid:

```text
VBoxContainer
├─ TitleHost (Control, fixed height)
├─ AspectRatioContainer
│  ├─ ratio = <measured width / height>
│  ├─ stretch_mode = STRETCH_FIT
│  ├─ size_flags_horizontal = EXPAND_FILL
│  ├─ size_flags_vertical = EXPAND_FILL
│  ├─ alignment_horizontal = CENTER
│  ├─ alignment_vertical = BEGIN
│  └─ GridContainer
│     ├─ columns = 2
│     ├─ h_separation = <measured>
│     └─ v_separation = <measured>
└─ (no footer after the ratio container; it consumes the rest)
```

### Size-flag trap

`AspectRatioContainer` does not set its own height from `width / ratio`. In a `VBoxContainer`:

- `SHRINK_BEGIN` gives the container its minimum size. The child grid can overflow below it.
- `EXPAND_FILL` gives it the remaining height.
- `STRETCH_WIDTH_CONTROLS_HEIGHT` sizes the child from width and can overflow when height is constrained.
- `STRETCH_FIT` fits the child inside both axes. This is the safe choice when a banner/footer reduces height.

Verify the result with the measurement script at the real design size. The exact numbers depend on the project's viewport, banner, and footer; the rule above is what transfers.

### Card size flags

A card scene that worked inside a custom container may not work inside `GridContainer`. Check the root:

```text
size_flags_horizontal = EXPAND_FILL (3)
size_flags_vertical = EXPAND_FILL (3)
```

`SHRINK_CENTER` (4) keeps the card at `custom_minimum_size`, even when the cell is larger.

## Explicit vertical rhythm

`VBoxContainer` applies `separation` between every child. If you also add a spacer, the effective gap is `separation + spacer`.

When matching measured concept spacing:

```text
VBoxContainer/separation = 0
TitleHost min height = <measured title block height>
Grid starts at <same value>
```

Use a spacer only when the separation is deliberately zero.

## Floating controls

Do not add a gear button to a `MarginContainer` or `SafeArea` container. The container will fit it to the content rect.

```text
ScreenRoot (Control)
├─ SafeArea (MarginContainer)
│  └─ padded content
├─ FloatingButton (Button, anchors bottom-right)
├─ ReservedSlot (Control, anchors bottom, height = platform banner height, mouse_filter ignore)
└─ Popup (Control)
```

The floating control sits above the reserved platform area. `ReservedSlot` reserves layout space but draws nothing.

## Card contents

A stable order that leaves the icon as the flexible region:

```text
Button
└─ Content (VBoxContainer, mouse_filter = IGNORE)
   ├─ Icon (TextureRect, vertical EXPAND_FILL,
   │        expand_mode = IGNORE_SIZE,
   │        stretch_mode = KEEP_ASPECT_CENTERED,
   │        texture_filter = NEAREST)
   ├─ Title (Label)
   ├─ Metadata (Label)
   └─ StatusRow (CenterContainer, mouse_filter = IGNORE)
      └─ StatusPill (PanelContainer, mouse_filter = IGNORE)
         └─ StatusLabel (Label)
```

Set `mouse_filter = IGNORE` on the pill and its parent. `PanelContainer` defaults to `STOP` and will eat the card click.

## Responsive checks

Test at the design size and at narrow widths:

- 320x568
- 375x667
- 430x932
- 720x1280
- 960x1280 tablet

For each, check:

- the grid keeps the intended aspect;
- labels do not clip or wrap unexpectedly;
- the reserved slot does not overlap floating controls;
- the floating controls remain reachable;
- no horizontal scroll appears.

## Measurement script

Use [measure_layout.gd](../scripts/measure_layout.gd) in a real Godot project:

```bash
SCENE=res://path/to/screen.tscn WIDTH=720 HEIGHT=1280 \
  godot --headless --path . -s /path/to/measure_layout.gd
```

The script instantiates the scene in a `SubViewport` at the requested size and prints each `Control`'s position, size, and minimum size. Do not trust the headless root viewport dimensions for layout measurements; use the explicit SubViewport.
