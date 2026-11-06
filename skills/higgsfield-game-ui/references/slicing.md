# Slicing and alpha

## Grid math

Given a sheet of width `W`, height `H`, `COLS`, `ROWS`:

```text
x0 = round(col * W / COLS)
x1 = round((col + 1) * W / COLS)
y0 = round(row * H / ROWS)
y1 = round((row + 1) * H / ROWS)
```

Use rounding, not integer division, so the last column/row does not lose pixels.

## Core centering

For each cell:

1. Find full alpha bounds: any pixel with `alpha > 0`.
2. Find core bounds: `alpha >= 0.8`.
3. If the core is empty, fail; the cell is empty or the threshold is wrong.
4. Compute the core center.
5. Compute `maxd`, the largest distance from the core center to a full-bounds edge.
6. Choose output `SIZE` and `MARGIN`.
7. `scale = min(1, (SIZE - 2*MARGIN) / (2*maxd))`.
8. For each output pixel, sample the source at the inverse-scaled offset from the core center.
9. Sample nearest-neighbor; do not anti-alias pixel art.
10. Save one file per icon.

This centers the **core**, not the glow. The full glow remains inside the canvas because the scale is derived from the farthest full-bounds edge.

## Script

[slice_icons_centered.gd](../scripts/slice_icons_centered.gd) implements the algorithm.

```bash
SOURCE=art/source/ui_icons_sheet.png \
OUT_DIR=assets/icons \
COLS=3 ROWS=2 \
NAMES=icon_a,icon_b,icon_c,icon_d,gear,sparkle \
SIZE=320 THRESHOLD=0.8 MARGIN=12 \
godot --headless --path . -s /path/to/slice_icons_centered.gd
```

`NAMES` must match `COLS * ROWS`. Use `gear` or other names as needed; the script does not know your output paths.

## Why a padded canvas, not a tight crop

- Pick a canvas comfortably above the largest runtime display size.
- A padded canvas leaves room for glow and keeps a stable layout.
- The icon core remains centered after the `TextureRect` scales it.
- A tight crop of the full alpha bounds has asymmetric margins and reintroduces the centering problem.

## Filtering

Set `TextureRect.texture_filter = 1` (nearest). Import PNGs without mipmaps. Avoid resizing the sliced PNG again unless the size is intentional.

## Alpha

- Prefer a transparent generation (`--background transparent`).
- If the model returns a fake checkerboard, reject it.
- If the model returns a solid background, key it or use additive blending on a dark UI.
- For neon on black, additive blending can look better than alpha and avoids edge fringing.
- Do not apply a hard luminance key without checking the glow; it can erase the bloom.

## Validation

- Every output is the expected `SIZE x SIZE`.
- Every core center is within 2px of the image center.
- No icon touches the canvas edge unless the source intentionally did.
- The full glow is not clipped.
- In the UI, the icon is visually centered in the card, not just in the file.
- A regression test covers all icons.
