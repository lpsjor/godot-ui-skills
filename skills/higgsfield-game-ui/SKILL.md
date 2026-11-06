---
name: higgsfield-game-ui
description: Generate and normalize game UI art with the Higgsfield CLI, including transparent icon spritesheets, gear and HUD icons, and starfield backgrounds. Use when a Godot UI needs generated pixel-art assets, when icons must be sliced from one sheet to save credits, or when generated art needs alpha cleanup and opaque-core centering.
---

# Higgsfield Game UI Assets

Generate only the art a UI cannot express with controls and theme: illustrations, icons, logos, and backgrounds. Never generate the card frame, pill, board frame, tile frame, or other UI chrome; those must stay in the theme so they remain editable and consistent.

Read `skill://higgsfield-generate` before running CLI commands. It owns authentication, model selection, media flags, and error handling. This skill covers the game-UI-specific prompt and post-processing loop.

## When to use

Use this skill when:

- The user wants mode icons, gear/HUD icons, a logo, or a starfield.
- One spritesheet can replace many one-off generations.
- Generated art needs transparent backgrounds, slicing, alpha cleanup, or centering.
- The user asks to reduce Higgsfield credit spend.

Do not use it for UI frames, buttons, pills, or layout. Do not generate copyrighted game assets or a concept's proprietary art unless the user has the rights.

## Preflight

1. Confirm the CLI works and the account is authenticated.
2. Inspect the model schema before passing parameters.
3. Estimate cost before generating.
4. Confirm the intended runtime size and whether transparency is required.

```bash
higgsfield account status
higgsfield model get gpt_image_2_6 --json
higgsfield generate cost gpt_image_2_6 \
  --prompt "pixel art icon sheet" \
  --aspect_ratio 3:2 \
  --resolution 2k \
  --quality high \
  --background transparent \
  --output_format png
```

Costs change. As of 2026-11-06, `gpt_image_2_6` at 2k/high was 2.75 credits and the default quality was `low`; always re-check rather than trusting a number in a skill.

## Choose the smallest useful set

| Asset | Generate? | Notes |
|---|---|---|
| Mode icons | Yes, one sheet | 4-9 equal cells; transparent. |
| Gear / undo / hint / pause | Yes, same or second sheet | Keep stroke weight consistent. |
| Starfield | Yes, one image | Transparent stars over a theme background. |
| Logo/title | Optional | Prefer a pixel font first; generate only if glow/lettering requires it. |
| Card frame, pill, board, tiles | No | Theme `StyleBox` resources. |
| UI layout/screenshot | No | Build with controls. |

One sheet with multiple icons is usually cheaper and more consistent than one job per icon. If a single cell fails, regenerate the sheet or repair only that cell; do not default to nine jobs.

## Spritesheet prompt

Use a fixed grid, equal cells, and a transparent background. State the exact icon order so the slicer is deterministic.

```text
A 3x2 sprite sheet of six isolated 8-bit pixel-art neon game icons.
One centered icon per equal cell, generous padding, no text, no labels,
no card frames, no grid lines, no checkerboard.
Pure transparent background. Consistent 4px pixel grid, hard square pixels,
no anti-aliasing, no 3D, no photorealism.
Palette: cyan #00CFFF, neon green #6BFF2A, magenta #FF3BD4,
yellow #FFD23F, off-white #F4F8E9.
Top row: 3x3 grid of glowing squares; Fibonacci spiral; pixel clock.
Bottom row: downward arrow above a tray; pixel gear; four-point star sparkle.
Use the supplied concept only as a palette and line-weight reference;
do not copy its layout, text, cards, or UI.
```

CLI shape:

```bash
higgsfield generate create gpt_image_2_6 \
  --prompt "$(cat prompt.txt)" \
  --image art/concepts/home.jpg \
  --aspect_ratio 3:2 \
  --resolution 2k \
  --quality high \
  --background transparent \
  --output_format png \
  --wait
```

Use `--image` only when the reference helps style. A full UI screenshot can bias the model toward copying the layout; the negative prompt must be explicit.

See [prompts](references/prompts.md) for sheet and starfield variants.

## Transparency

`gpt_image_2_6` accepts `--background transparent`. Verify the result actually has alpha:

```bash
file icon_sheet.png
sips -g hasAlpha icon_sheet.png
```

If the model returns a fake checkered background, a solid background, or an alpha edge that is unusable:

1. Prefer a flat background color that does not occur in the art and key it locally.
2. For pure neon on black, keep the black background and use additive blending in Godot.
3. Never ship a checkerboard image.

For icons, a black-background asset can also be converted to alpha by luminance, but inspect glow edges first. For starfields, additive blending often looks better than hard alpha.

## Slice and normalize

Do not ship the raw sheet unless the UI uses an `AtlasTexture` deliberately. For editor preview and simple per-mode files, slice into individual PNGs.

1. Divide the sheet into the declared grid.
2. Trim only the transparent padding, not the glow asymmetrically.
3. Find the opaque core (`alpha >= 0.8`).
4. Center the core in a padded canvas, keeping the full glow.
5. Resize with nearest filtering.
6. Write one file per icon with stable names.
7. Verify each core center is within 2px of the image center.

Use [slice_icons_centered.gd](scripts/slice_icons_centered.gd). It supports a source path, grid dimensions, names, output directory, threshold, and canvas size through environment variables.

See [slicing](references/slicing.md) for the algorithm and validation.

## Starfield

Prompt for stars only, not a full background with baked UI:

```text
A sparse 9:16 pixel-art starfield for a neon 2048-like puzzle game.
Deep navy-black space, scattered tiny square stars, a few larger four-point
cyan and magenta sparkles with soft glow, small white stars, subtle depth.
No planets, no nebula clouds, no text, no UI, no card shapes, no gradient bands.
Crisp 8-bit pixel art with hard square pixels, transparent background.
```

Use the generated image as a Home-specific `TextureRect` over a theme background. Do not overwrite the shared screen chrome if only one screen should change.

## Cost discipline

- Check `higgsfield generate cost` before every new asset class.
- Use `--quality high` deliberately; omitting quality can silently select `low`.
- Generate one sheet, slice locally.
- Use 2k for icons and backgrounds; 4k only when the runtime target genuinely needs it.
- Prefer hand-authored 9-patch glow and theme frames to generated UI chrome.
- Treat retries as part of the budget; one failed sheet should not become a batch of jobs.

## Security and provenance

- Inspect generated files before integrating them.
- Keep the source sheet and a short prompt/source note outside runtime assets.
- Do not commit generated assets whose rights are unclear.
- Do not put credentials or API keys in prompts, scripts, or the skill.

## Reference map

- [Prompts](references/prompts.md) — sheet and starfield prompt templates.
- [Slicing](references/slicing.md) — grid math, core centering, alpha and validation.
- The companion `godot-pixel-ui` skill covers font, icon, and glow integration.

## Output expectation

Leave behind:

- A source sheet with prompt/model/date provenance.
- Transparent, correctly sliced runtime PNGs.
- Core-centered icons with a regression check.
- A Home-specific starfield if needed.
- No generated UI chrome.
