# Pixel fonts

## Selection

Choose a font that has:

- the scripts the product ships;
- an OFL or otherwise commercial-friendly license;
- a pixel grid that matches the UI scale;
- a file size acceptable for the app.

Fusion Pixel 12px is a useful reference for pan-CJK coverage. It is available in per-language proportional or monospaced variants and includes OFL and upstream license files. Do not assume every "pixel font" includes CJK; check coverage.

## Subsetting

A full CJK font can be several megabytes per language. Subset to the characters the UI actually displays.

Extract the union of every localization string plus printable ASCII:

```bash
python3 - <<'PY'
import csv
chars = set(chr(c) for c in range(0x20, 0x7f))
with open("path/to/messages.csv", newline="", encoding="utf-8") as f:
    for row in csv.reader(f):
        for value in row[1:]:
            chars.update(value)
open("/tmp/ui-chars.txt", "w", encoding="utf-8").write("".join(sorted(chars)))
PY
```

Subset one source variant per locale:

```bash
pyftsubset fusion-pixel-12px-proportional-zh_hant.ttf \
  --text-file=/tmp/ui-chars.txt \
  --output-file=assets/fonts/fusion-pixel-12px-zh_TW.ttf \
  --layout-features='*' \
  --glyph-names --notdef-glyph --notdef-outline --recommended-glyphs \
  --name-IDs='*' --name-languages='*' --name-legacy
```

Repeat for `latin` (en), `zh_hans` (zh_CN), `ja`, and `ko`. Keep the upstream OFL license and a source note with the version.

Subsetting means a future string with a new glyph may fall back to the project font. Keep a fallback or regenerate the subset when the localization table changes.

## Import settings

For a dynamic pixel font:

```text
antialiasing=0
generate_mipmaps=false
hinting=0
subpixel_positioning=0
allow_system_fallback=false
multichannel_signed_distance_field=false
oversampling=0.0
```

The values live in the generated `.import` file. Re-import after changing them and inspect the result at runtime; do not trust the editor font preview alone.

## Sizes

Use integer multiples of the font's pixel grid. For a 12px font:

```text
24  = 2x
36  = 3x
48  = 4x
72  = 6x
96  = 8x
```

Arbitrary sizes (for example 40 or 42) reintroduce blur even with antialiasing disabled.

## Line height is not font size

A `Label`'s minimum height comes from the font's line height, not the requested font size. A 96px pixel font can produce a ~140px minimum height because of ascent, descent, and line spacing.

Consequences:

- `vertical_alignment` centers the glyph inside that line box; it does not remove the extra height.
- Hardcoded spacers tuned to the font size will be too small.
- A title that looks vertically centered in the inspector can sit far below the visual top of its container.

Measure before positioning:

```gdscript
label.get_combined_minimum_size().y
```

If the concept needs exact glyph placement:

1. Prefer a fixed-height host `Control` with the Label explicitly offset, and document that the offset follows the font's metrics.
2. Or use a generated logo/`TextureRect` when the title is fixed brand art.
3. Or accept the line box and adjust the surrounding layout.

Do not copy a magic negative offset into another project without re-measuring at the target font and size.

For English-only metadata such as `SCORE` or `LEVEL`, `Label.uppercase = true` can avoid duplicate uppercase localization strings; CJK strings are unaffected.

## FontVariation and locale switching

Use a `FontVariation` resource so a screen's pixel font can be swapped without touching the project default:

```text
resources/ui/screen_pixel_font.tres
  base_font = fusion-pixel-12px-en.ttf
  fallbacks = [<normal UI font per locale>]
```

At runtime, switch `base_font` to the locale-specific subset:

```gdscript
static func screen_font_path(locale: String) -> String:
    match locale:
        "zh_CN": return "res://assets/fonts/fusion-pixel-12px-zh_CN.ttf"
        "zh_TW": return "res://assets/fonts/fusion-pixel-12px-zh_TW.ttf"
        "ja": return "res://assets/fonts/fusion-pixel-12px-ja.ttf"
        "ko": return "res://assets/fonts/fusion-pixel-12px-ko.ttf"
        _: return "res://assets/fonts/fusion-pixel-12px-en.ttf"
```

Assign the variation only to screen-specific theme variations:

```text
ScreenTitle/fonts/font = ScreenPixelFont
CardTitle/fonts/font = ScreenPixelFont
CardText/fonts/font = ScreenPixelFont
```

Leave the project `default_font` on the normal UI font.

## Spacing

If a title needs wider letter spacing, create a second `FontVariation` whose `base_font` is the screen pixel variation and set `spacing_glyph`. Do not widen the shared body font; it will break card titles and status pills.

## CJK verification

Render every locale:

- longest localized label;
- secondary metadata line;
- status pill translations;
- title;
- other screens, to confirm they did not inherit the screen font.

Check line height and clipping, not only glyph coverage. A font can have the glyph and still overflow the pill's height.

## License

Ship the upstream OFL text and a source note:

```text
Fusion Pixel Font 12px proportional
Version: 2026.10.25
Source: https://github.com/TakWolf/fusion-pixel-font
License: SIL Open Font License 1.1
Subsets: generated for the project localization table
```

Do not commit a font without its license.
