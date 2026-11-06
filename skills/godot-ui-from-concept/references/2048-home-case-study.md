# Case study: 2048 Home

This is a worked example, not a universal specification. The values below were measured for one 720x1280 concept and one Godot project. Re-measure for a new concept.

## Starting point

The existing Home was a theme-driven screen, but it used:

- a centered square-card grid (`SquareGrid`)
- a tagline and card intro lines
- a max-tier tile beside the best score
- a settings gear anchored to the top-right
- a visible banner label
- the shared GameUI font

The concept required:

- a tighter 2x2 block of tall cards
- a large pixel title
- four accent colors
- icon, name, best score, and `RESUME`/`NEW` pill
- a bottom-right gear
- space for a native banner at the bottom

## Measured target (example)

| Item | Value |
|---|---|
| Design viewport | 720x1280 |
| Outer left/right | ~44 design px |
| Title block | ~y84–278 |
| Grid block | ~y278–1084 |
| Card size | ~284x393 |
| Card aspect | ~0.72 |
| Grid | 2 columns, ~24/20 separation |
| Banner reserve | 100 design px |
| Gear | 96x96 touch box above the banner |

## Scene decisions

```text
Home (ScreenChrome)
├─ Background (HomeScreenBackground)
│  └─ HomeStars (TextureRect)
├─ Starfield (hidden on Home)
├─ SafeArea
│  └─ HomePadding
│     └─ Shell
│        └─ Column
│           ├─ TitleHost
│           │  └─ Title
│           └─ GridAspect (AspectRatioContainer)
│              └─ ModeGrid (GridContainer)
│                 └─ four ModeCard buttons
├─ SettingsButton (anchors bottom-right)
├─ BannerSlot (Control, 100 high)
└─ SettingsPopup
```

Why:

- `AspectRatioContainer` with `STRETCH_FIT` + `EXPAND_FILL` preserved the card block when the banner and gear reduced available height.
- `GridContainer` kept the 2x2 arrangement native and editor-previewable.
- The gear stayed outside `SafeArea`'s `MarginContainer`; otherwise the container would lay it out.
- `BannerSlot` drew nothing; the native ad overlay occupies it.
- Home used its own background variation and starfield so Game/Settings were untouched.

## Theme decisions

Home-only variations:

```text
HomeTitle
HomeCardClassic / Fib / Timed / Gravity
HomeNameClassic / Fib / Timed / Gravity
HomeTextClassic / Fib / Timed / Gravity
HomePillClassic / Fib / Timed / Gravity
HomeGear
HomeGrid
HomePadding
HomeScreenBackground
```

Each card variation had normal/hover/pressed styleboxes in its accent. The shared base variation held the common states. Labels and pills had their own variations because theme variation is not inherited across node types.

## Failures found and fixes

### 1. AspectRatioContainer overflow

With `size_flags_vertical = SHRINK_BEGIN`, the ratio container stayed at its minimum height and the grid overflowed. With `STRETCH_WIDTH_CONTROLS_HEIGHT`, the grid overflowed when the banner/footer constrained height.

Fix:

```text
stretch_mode = STRETCH_FIT
size_flags_vertical = EXPAND_FILL
alignment_vertical = BEGIN
```

Measured result: 632x810 available -> 595x810 grid -> 290x397 cards, no overflow.

### 2. Cards stayed at minimum size

The existing card root had `size_flags_horizontal = SHRINK_CENTER` and `size_flags_vertical = SHRINK_CENTER`. Inside the custom `SquareGrid`, the parent forced the size; inside `GridContainer`, the card stayed 160x220.

Fix: `EXPAND_FILL` on both axes.

### 3. Ghost spacing

The `VBoxContainer` separation added an extra 12px on top of an explicit gap. Fix: separation `0`; let the explicit spacer or title block own the rhythm.

### 4. Gear moved into the container

The gear was a child of `SafeArea` (a `MarginContainer`), so the container fitted it to the content rect instead of respecting the bottom-right anchors. Fix: make it a child of the plain screen root.

### 5. Pill ate clicks

`StatusPill` was a `PanelContainer` with the default `mouse_filter = STOP`. The card's click stopped at the pill. Fix: `IGNORE` on the content, status row, pill, and label.

### 6. Hard glow

`StyleBoxFlat.shadow` produced a hard halo, not the concept's soft neon bloom. Fix: per-mode `StyleBoxFlat` border + a white-alpha `NinePatchRect` glow behind the card, tinted with the mode accent.

### 7. Icons off-center

Slicing by the full alpha bounds centered the asymmetric glow, not the visible icon. Core centers were off by up to 24px. Fix: find the `alpha >= 0.8` core, center that in the output canvas, preserve the full glow, and add a regression test.

### 8. Resume state lied

`SaveService.has_run()` is true for dead and timed-out runs. The card displayed `RESUME`, but opening it restored a dead board and immediately showed the game-over modal. Fix: resume only when the saved status is `playing`; otherwise start a new run and show `NEW`.

### 9. Old tests pinned the old layout

Tests asserted square cards, an intro line, a top-right gear, and a max-tier tile. These were replaced with ratio, status, icon-center, and bottom-anchor assertions. The tests were not deleted to make the build green.

### 10. Global font/background leakage

Changing `theme.default_font` or the shared `ScreenChrome` starfield affected Game and Settings. Fix: put the pixel font on Home-specific variations; add a Home-specific background/starfield.

## Asset pipeline

- One 3x2 Higgsfield icon sheet: four mode icons, gear, spare.
- One 9:16 starfield.
- 2k, high quality, transparent, PNG.
- Cost at the time: 2.75 credits per job; no frame/logo generation.
- Source sheet kept outside runtime assets; runtime files sliced to individual PNGs.
- 9-patch glow generated locally, not with AI.

## Final values

- Cards ~284x393 at 720x1280.
- Grid ~595x810 with banner/gear reserved.
- Gear 96x96 touch box; icon max 56.
- Banner slot 100 design px.
- Pixel font 12px grid; title 96, card name 36, best/status 24.
- Title uses a separate `FontVariation` with `spacing_glyph` for width.

## What generalized

- Use native containers before custom ones.
- Ratio containers need explicit expansion and fitting.
- A theme variation chain is a practical per-mode state system.
- Keep one screen's font/background scoped to that screen.
- Center AI icons by opaque core.
- Keep glow separate from the border.
- Treat save status, not run existence, as the resume signal.
- Update tests to a new layout contract.

## What did not generalize

- The exact colors, spacing, and card sizes.
- The four-mode palette as a universal palette.
- The 100px banner height; native ad sizes vary.
- The specific font file; any compliant pixel font with locale coverage can work.
- The assumption that `.agents/skills` is the only install path.
