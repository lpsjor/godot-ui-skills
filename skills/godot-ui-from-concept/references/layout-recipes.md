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
│  ├─ ratio = 0.735
│  ├─ stretch_mode = STRETCH_FIT
│  ├─ size_flags_horizontal = EXPAND_FILL
│  ├─ size_flags_vertical = EXPAND_FILL
│  ├─ alignment_horizontal = CENTER
│  ├─ alignment_vertical = BEGIN
│  └─ GridContainer
│     ├─ columns = 2
│     ├─ h_separation = 24
│     └─ v_separation = 20
└─ (no footer after the ratio container; it consumes the rest)
```

### Size-flag trap

`AspectRatioContainer` does not set its own height from `width / ratio`. In a `VBoxContainer`:

- `SHRINK_BEGIN` gives the container its minimum size. The child grid can overflow below it.
- `EXPAND_FILL` gives it the remaining height.
- `STRETCH_WIDTH_CONTROLS_HEIGHT` sizes the child from width and can overflow when height is constrained.
- `STRETCH_FIT` fits the child inside both axes. This is the safe choice when a banner/footer reduces height.

Measured example at a 720x1280 design viewport with a 100px banner and a 96px gear footer:

```text
content width = 632
available ratio height = 810
grid = 595x810
cards = 290x397
```

With no footer, a 632-wide ratio block produced a 632x860 grid and 304x420 cards. The values are example evidence, not invariants.

### Card size flags

A card scene that worked inside a custom container may not work inside `GridContainer`. Check the root:

```text
size_flags_horizontal = EXPAND_FILL (3)
size_flags_vertical = EXPAND_FILL (3)
```

`SHRINK_CENTER` (4) keeps the card at `custom_minimum_size`; a 160x220 card stays 160x220 in a 290px cell.

## Explicit vertical rhythm

`VBoxContainer` applies `separation` between every child. If you also add a spacer, the effective gap is `separation + spacer`.

When matching measured concept spacing:

```text
VBoxContainer/separation = 0
TitleHost min height = 194
Grid starts at 194
```

Use a spacer only when the separation is deliberately zero.

## Floating controls

Do not add a gear button to a `MarginContainer` or `SafeArea` container. The container will fit it to the content rect.

```text
ScreenRoot (Control)
├─ SafeArea (MarginContainer)
│  └─ padded content
├─ Gear (Button, anchors bottom-right)
├─ BannerSlot (Control, anchors bottom, height 100, mouse_filter ignore)
└─ SettingsPopup (Control)
```

The gear sits above the native banner area. `BannerSlot` reserves layout space but draws nothing.

## Card contents

A stable order that leaves the icon as the flexible region:

```text
Button
└─ Content (VBoxContainer, mouse_filter = IGNORE)
   ├─ Icon (TextureRect, vertical EXPAND_FILL,
   │        expand_mode = IGNORE_SIZE,
   │        stretch_mode = KEEP_ASPECT_CENTERED,
   │        texture_filter = NEAREST)
   ├─ Name (Label)
   ├─ BestScore (Label)
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
- the banner slot does not overlap the gear;
- the settings button remains reachable;
- no horizontal scroll appears.

## Measurement script

Use [measure_layout.gd](../scripts/measure_layout.gd) in a real Godot project:

```bash
SCENE=res://scenes/home/home.tscn WIDTH=720 HEIGHT=1280 \
  godot --headless --path . -s /path/to/measure_layout.gd
```

The script instantiates the scene in a `SubViewport` at the requested size and prints each `Control`'s position, size, and minimum size. Do not trust the headless root viewport dimensions for layout measurements; use the explicit SubViewport.
