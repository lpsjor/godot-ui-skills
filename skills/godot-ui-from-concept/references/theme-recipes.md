# Theme recipes

## Variation chains

Godot 4 supports a theme variation whose base is another variation. This is useful for per-mode cards:

```text
Button
└─ HomeCard (common hover/pressed/focus/disabled)
   ├─ HomeCardClassic (normal = cyan border)
   ├─ HomeCardFib (normal = green border)
   ├─ HomeCardTimed (normal = magenta border)
   └─ HomeCardGravity (normal = yellow border)
```

Each child only overrides what differs. The common states still resolve through the base variation.

Tested in Godot 4.7.2 with a live `Button` in the tree:

```text
theme_type_variation = "HomeCardClassic"
get_theme_stylebox("hover") -> StyleBox from the base variation
```

A variation chain does not cascade Label colors into Button children. Give Labels their own variations:

```text
HomeName (Label; pixel font, 36px)
├─ HomeNameClassic
├─ HomeNameFib
├─ HomeNameTimed
└─ HomeNameGravity

HomeText (Label; pixel font, 24px)
├─ HomeTextClassic
├─ HomeTextFib
├─ HomeTextTimed
└─ HomeTextGravity
```

## Per-mode states

For a mode card, define at least:

- `normal`
- `hover`
- `pressed`
- `focus` (or disable focus deliberately)
- `disabled` if the card can be disabled

Do not leave `hover`/`pressed` unset on a per-mode variation if the base `Button` has a different accent; the card will change color on hover.

The 2048 implementation uses:

- 4 mode variations × normal/hover/pressed
- 4 name text variations
- 4 best/status text variations
- 4 status pill variations
- one shared gear variation
- one shared home background variation
- one shared title variation

## Screen-local fonts

Changing the project `default_font` changes every screen. For a screen-local pixel font:

1. Create a `FontVariation` resource.
2. Put it on screen-specific Label variations.
3. Leave the project default and other screens alone.
4. Switch the variation's `base_font` when the locale changes, if the font has locale-specific files.

```text
Project default_font = GameUI
HomeTitle/fonts/font = HomePixelFont
HomeName/fonts/font = HomePixelFont
HomeText/fonts/font = HomePixelFont
```

A title may use a second variation with `spacing_glyph` for wider letter spacing. Do not add spacing to the shared body font.

## Screen-local background

Shared `ScreenChrome` background and starfield affect every screen. If only one screen should change:

- Add a screen-specific `Background` theme variation, or
- Add a screen-specific `TextureRect` child, or
- Swap the texture on the screen instance only.

Do not rewrite the shared `ScreenChrome` scene for one screen unless all screens are intentionally changing.

## Border vs glow

Use two separate mechanisms:

| Layer | Mechanism | Purpose |
|---|---|---|
| Card border/fill | Per-mode `StyleBoxFlat` | Hard pixel border, fill, hover/pressed states |
| Soft neon bloom | `NinePatchRect` + white-alpha texture | Avoid `StyleBoxFlat` shadow's hard halo |

`StyleBoxFlat.shadow` is not a soft Gaussian bloom. It produces a hard expanded shadow at these sizes. If the concept needs a soft glow, use a 9-patch glow layer behind the card, or a shader.

```text
Button
├─ Glow (NinePatchRect, show_behind_parent = true, mouse_filter = ignore)
└─ Content
```

The glow texture's center should be transparent. The button stylebox supplies the fill; the glow supplies only the halo.

For pixel-style frames, keep `StyleBoxFlat.anti_aliasing = false`, use a small `corner_radius`, and lower `corner_detail` to get a faceted rather than smooth corner. The border remains intentionally hard; the glow is the soft layer.

## Editor preview

- Keep the theme in a `.tres` file tracked by git.
- Use `@tool` only for components that need live data.
- In editor mode, do not read save files. Show `preview_status` or equivalent.
- Expose ratio, separation, padding, and font sizes through the theme or inspector.
- Do not use runtime `Theme.new()` for a screen the editor must preview.
- Do not use `add_theme_stylebox_override()` / `add_theme_font_override()` to create the visual design.

## Naming

Use short, stable, screen-scoped names:

```text
HomeTitle
HomeCardClassic / HomeCardFib / HomeCardTimed / HomeCardGravity
HomeNameClassic / ...
HomeTextClassic / ...
HomePillClassic / ...
HomeGear
HomeGrid
HomePadding
HomeScreenBackground
```

Do not name a variation after a temporary value such as `HomeCardBlue2`.

## Theme file hygiene

- Keep one source of truth for the palette.
- Avoid dead variations after a component is removed.
- Keep common states on a base variation.
- Use `StyleBoxFlat` for crisp rectangular borders; use 9-patch only when the texture adds real value.
- Check that the theme still loads with no missing subresources after edits.
