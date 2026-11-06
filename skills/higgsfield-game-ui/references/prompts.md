# Prompt templates

Use `skill://higgsfield-generate` for the CLI contract. These are game-UI-specific prompts.

## Icon sheet

```text
A {COLS}x{ROWS} sprite sheet of {COUNT} isolated 8-bit pixel-art neon game icons.
One centered icon per equal cell, generous padding, no text, no labels,
no card frames, no grid lines, no checkerboard.
Pure transparent background. Consistent 4px pixel grid, hard square pixels,
no anti-aliasing, no 3D, no photorealism.
Palette: cyan #00CFFF, neon green #6BFF2A, magenta #FF3BD4,
yellow #FFD23F, off-white #F4F8E9.
Icons, in reading order: {ICON LIST}.
Use the supplied image only as a palette and line-weight reference;
do not copy its layout, text, cards, or UI.
```

### Negative list

Add explicitly:

```text
no letters, no numbers, no labels, no captions, no UI panels,
no card frames, no borders around cells, no grid lines,
no checkerboard, no watermark, no 3D render, no photographic texture.
```

### Reference image

A full UI concept can bias the model toward copying the layout. If the model does:

- crop a palette/icon reference first;
- say "reference only";
- add the negative list;
- if it still copies, generate without the image and describe the palette.

## Starfield

```text
A sparse {ASPECT} pixel-art starfield background for a neon puzzle game.
Deep navy-black space, scattered tiny square stars, a few larger four-point
cyan and magenta sparkles with soft glow, small white stars, subtle depth.
No planets, no nebula clouds, no text, no UI, no card shapes, no gradient bands.
Crisp 8-bit pixel art with hard square pixels, transparent background.
Match the star density and palette of the reference, but not its layout or UI.
```

If the result is a full opaque background instead of transparent stars, keep the opaque version only if the screen can use the baked background. Otherwise key it or use additive blending.

## Logo/title

Only generate if a pixel font plus outline/shadow is not enough. A generated logo should be fixed brand art, not localized text.

```text
Pixel-art wordmark "2048", isolated on a transparent background,
cyan neon face, dark outline, soft outer glow, hard square pixels,
no extra text, no card, no mockup, centered.
```

## Parameters

```bash
--aspect_ratio 3:2          # 3x2 sheet; use 1:1 for 3x3
--resolution 2k
--quality high              # default is low; specify deliberately
--background transparent
--output_format png
--image art/concepts/home.jpg   # optional style reference
--wait
```

Check the model schema first; accepted enum values can change.

## Cost

Run:

```bash
higgsfield generate cost gpt_image_2_6 \
  --prompt "pixel art icon sheet" \
  --aspect_ratio 3:2 \
  --resolution 2k \
  --quality high \
  --background transparent \
  --output_format png
```

Example observed on 2026-11-06: 2.75 credits at 2k/high. Re-check; do not hardcode current pricing into a workflow.

## Output checks

- Does the sheet have the exact number of cells?
- Is any text or grid line present?
- Is the background truly transparent?
- Are icons consistent in stroke weight and palette?
- Does each icon have enough padding for its glow?
- Is a single cell bad enough to justify a new job?

If one cell is bad, repair/crop or regenerate the sheet; do not silently ship a broken cell.
