---
name: godot-pixel-ui
description: Build pixel-art UI in Godot 4 with pixel fonts, CJK subsets, nearest filtering, opaque-core icon centering, and soft 9-patch neon glow. Use when a UI needs a pixel look, when text must stay crisp across locales, when icons look off-center inside their textures, or when a hard StyleBox shadow is not an acceptable glow.
---

# Pixel UI in Godot

Pixel UI fails in small, specific ways: the font is blurred by import settings, CJK falls back to a smooth font, an AI glow shifts the icon's visual center, or a StyleBox shadow produces a hard halo instead of neon bloom. This skill covers those failure modes.

Use it together with `godot-ui-from-concept`; that skill owns layout and theme architecture. This one owns pixel typography, icon processing, and glow layering.

## When to use

Use this skill when:

- A concept uses pixel or bitmap typography.
- The UI must display Latin and CJK with the same visual language.
- Icons come from an AI spritesheet and need deterministic slicing.
- A neon frame needs a soft glow rather than a `StyleBoxFlat` shadow.
- The user complains that pixel text/icons are blurry, clipped, or off-center.

Do not use it to generate the art itself; use `higgsfield-game-ui` for generation and this skill for normalization and integration.

## Pixel font pipeline

### 1. Pick a font with the required coverage

Prefer an OFL-licensed pixel font with the scripts the product actually ships. For pan-CJK UI, a 12px proportional font such as Fusion Pixel is a proven reference, but any equivalent OFL font works.

Confirm:

- glyph coverage for every locale;
- license permitting commercial use;
- a pixel grid size that maps to the UI's font sizes;
- file size acceptable for the project.

Do not mix a pixel Latin font with a smooth CJK fallback unless the mixed typography is an explicit design decision.

### 2. Keep the font files small

Subset each locale to the characters used by the UI. A practical approach:

1. Extract every character from the localization table plus printable ASCII and punctuation.
2. Run `pyftsubset` per language variant.
3. Commit the subsets and the upstream OFL license.
4. Keep a source note with upstream version and URL.

Reference: [pixel fonts](references/fonts.md).

### 3. Configure Godot's font import for pixels

For a dynamic pixel font, disable filtering-like behavior:

```text
antialiasing=0
generate_mipmaps=false
hinting=0
subpixel_positioning=0
allow_system_fallback=false
multichannel_signed_distance_field=false
oversampling=0.0
```

Then use font sizes that are integer multiples of the font's pixel grid. A 12px font maps naturally to 24, 36, 48, 72, and 96. Arbitrary sizes reintroduce blur.

### 4. Isolate the pixel font to the screen

Do not change the project `default_font` if only one screen is pixel-styled.

Create a `FontVariation` resource per locale or a single variation whose `base_font` is switched at runtime. Put it on screen-specific Label variations. Leave the game and settings screens on the project font.

```text
Project default_font = normal UI font
ScreenTitle/fonts/font = ScreenPixelFont
CardTitle/fonts/font = ScreenPixelFont
CardText/fonts/font = ScreenPixelFont
```

If the title needs wider letter spacing, use a second `FontVariation` with `spacing_glyph`; do not widen all card text.

### 5. Verify the actual text, not the font resource

- Render every locale at the target sizes.
- Check for clipped descenders, clipped status pills, and overflow in the longest localized label.
- Test a fresh save and a saved-run state.
- Confirm the pixel font is only used where intended.

## Icon pipeline

### 1. Start from a clean sheet

Generate one spritesheet with equal cells and generous padding. Keep the source sheet outside runtime assets; keep runtime slices in the project's asset directory.

### 2. Center the opaque core, not the glow

AI neon icons have asymmetric bloom. The full alpha bounding box can be centered while the visible icon is visibly off-center.

Use this rule:

1. Find the bounding box of pixels with `alpha >= 0.8` (the opaque core).
2. Find the full alpha bounds to preserve glow.
3. Scale and translate so the **core center** lands at the output center.
4. Keep enough padded canvas for the full glow.
5. Add a regression test that the core center is within 2px of the image center.

Use [slice_icons_centered.gd](scripts/slice_icons_centered.gd) as a starting point. The script is intentionally standalone; copy it into a Godot project and provide environment variables.

### 3. Preserve pixel edges

- Import icons with nearest filtering (`texture_filter = 1` on the `TextureRect` or import setting).
- Avoid non-integer downscales where possible.
- Normalize each icon to a padded power-of-two-ish canvas (for example 320x320) rather than tightly cropping to the glow.
- Keep source PNGs transparent; do not bake a checkerboard.

### 4. Verify in context

Check the icon against the card center line, not only in an image viewer. A core-centered PNG can still look wrong if the card content is asymmetric.

## Soft neon glow

`StyleBoxFlat.shadow` is a hard halo at these sizes. It is useful for a crisp border, not for neon bloom.

Use a two-layer approach:

- `StyleBoxFlat` on the `Button` for the 4px border, fill, and hover/pressed states.
- A white-alpha 9-patch glow texture on a `NinePatchRect` child behind the Button.

Glow setup:

```text
NinePatchRect
  show_behind_parent = true
  mouse_filter = IGNORE
  anchors full, offsets negative to extend outside the card
  patch margins match the glow texture
  modulate = accent color with alpha
```

Set the glow color from the same theme accent as the card text/pill. On hover, raise the glow alpha; do not replace the border with the base Button style.

Generate the glow texture with [gen_ninepatch_glow.gd](scripts/gen_ninepatch_glow.gd), or hand-author a pixel-stepped ring. Keep the center transparent so the card fill remains separate.

## Pixel scaling limits

`canvas_items` with a 720x1280 design viewport is fractionally scaled on a 375-wide phone. You cannot promise every logical pixel maps to one physical pixel.

- Test at 320, 375, 430, and 720 widths.
- Use nearest filtering for icons; decide deliberately for glows and starfields.
- Do not claim pixel-perfect output without a pixel-perfect scaling strategy.
- Keep touch targets in design units, not physical pixels.

## Reference map

- [Pixel fonts](references/fonts.md) — selection, subsetting, import settings, locale switching.
- [Icons and glow](references/icons-and-glow.md) — core centering, 9-patch layering, filtering, tests.
- [slice_icons_centered.gd](scripts/slice_icons_centered.gd) — grid slicing with opaque-core centering.
- [gen_ninepatch_glow.gd](scripts/gen_ninepatch_glow.gd) — white-alpha soft glow texture generator.

## Output expectation

Leave behind:

- Font assets with license and source notes.
- Import settings that do not blur pixel text.
- Screen-scoped font variations.
- Icons centered by opaque core and verified in the card.
- A 9-patch glow layer with per-variant tint.
- Screenshots at the target sizes and locales.
