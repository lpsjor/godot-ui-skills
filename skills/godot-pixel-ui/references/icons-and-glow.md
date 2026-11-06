# Icons and glow

## Why full-alpha centering fails

AI neon icons have asymmetric glow. The full alpha bounding box may be centered while the solid icon is 15–24px off-center. A viewer perceives the solid shape, not the bloom.

Measure both:

- **core bounds**: pixels with `alpha >= 0.8`
- **full bounds**: any non-transparent pixel

Center the core, leave room for the full bounds.

## Slicing algorithm

Use [slice_icons_centered.gd](../scripts/slice_icons_centered.gd).

```bash
SOURCE=/path/to/sheet.png \
OUT_DIR=/path/to/assets/mode \
COLS=3 ROWS=2 \
NAMES=classic,fib,timed,gravity,gear,sparkle \
SIZE=320 THRESHOLD=0.8 MARGIN=12 \
godot --headless --path /path/to/project -s /path/to/slice_icons_centered.gd
```

The script:

1. Divides the source into `COLS x ROWS` cells.
2. Finds the core bounds (`alpha >= THRESHOLD`) and full bounds.
3. Computes the maximum distance from the core center to any full-bounds edge.
4. Scales the cell so the full glow fits the output canvas with a margin.
5. Samples nearest-neighbor with the core center at the output center.
6. Writes one PNG per name.

Output sizes: 320 for card icons, 256 for a gear/HUD icon. Keep the canvas padded; do not tightly crop the glow.

## Validation

```gdscript
var img := texture.get_image()
var lo := Vector2i(99999, 99999)
var hi := Vector2i(-1, -1)
for y in img.get_height():
    for x in img.get_width():
        if img.get_pixel(x, y).a >= 0.8:
            lo.x = mini(lo.x, x); lo.y = mini(lo.y, y)
            hi.x = maxi(hi.x, x); hi.y = maxi(hi.y, y)
var center := (Vector2(lo) + Vector2(hi)) * 0.5
var target := Vector2(img.get_width(), img.get_height()) * 0.5
assert(center.distance_to(target) <= 2.0)
```

Run this for every mode icon in the test suite.

## Filtering

- `TextureRect.texture_filter = 1` (nearest) for pixel icons.
- Import the PNG without mipmaps.
- Avoid non-integer downscales where possible.
- Keep the icon centered in the card, not only in the file.

## 9-patch glow

Do not use `StyleBoxFlat.shadow` for soft neon. Use a `NinePatchRect` behind the card.

### Texture

A 64x64 white-alpha texture with a transparent center:

- `BAND = 12`: distance from the outer edge to the glow peak
- `INNER = 24`: fade-out radius
- alpha is a smooth ring, transparent at the center and outside
- patch margins 24
- no color baked in; tint with `modulate`

Generate with [gen_ninepatch_glow.gd](../scripts/gen_ninepatch_glow.gd).

### Filtering

- Glow texture: linear filtering; a soft bloom should not stair-step.
- Pixel icons and borders: nearest filtering.
- Do not apply one filter setting to the whole card if it makes either layer wrong; set it per texture-bearing node.

### Scene

```text
ModeCard (Button, clip_contents = false)
├─ Glow (NinePatchRect)
│  ├─ show_behind_parent = true
│  ├─ mouse_filter = 2
│  ├─ anchors full
│  ├─ offsets -12 on all sides
│  ├─ texture = card_glow.png
│  ├─ patch margins 24
│  └─ modulate = accent with alpha 0.78
└─ Content (VBoxContainer, mouse_filter = 2)
```

Set `clip_contents = false` on the card, or the child glow's negative offsets are clipped at the card bounds.

### Theme tint

Set the glow color from the same accent used by the card's text/pill:

```gdscript
var accent := get_theme_color("font_color", &"HomeText%s" % suffix)
_glow.modulate = Color(accent.r, accent.g, accent.b, 0.78)
```

On hover, raise alpha to 1.0; on exit, restore 0.78. Do not replace the per-mode border with the base Button style.

### Why not StyleBoxTexture

A `StyleBoxTexture` can work for a full frame, but glow outside the stylebox rect and 9-patch expansion are easy to get wrong. A separate `NinePatchRect` behind the button keeps the border and glow independent and easier to tune.

## Pixel scaling

Fractional canvas scaling means pixel-perfect output is not guaranteed. Test real screenshots at 320/375/430/720. Nearest filtering keeps hard edges but can produce uneven pixel widths; that is a known limit, not a bug in the slicer.
