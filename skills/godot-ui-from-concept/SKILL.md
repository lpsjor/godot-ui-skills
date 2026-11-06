---
name: godot-ui-from-concept
description: Reconstruct a UI concept in Godot 4 with native Control and Container nodes, a theme-driven layout, and editor-previewable states. Use when the user supplies a mockup or concept image and asks to rebuild or restyle a Godot screen, or asks about theme variations, responsive card grids, banner-safe layouts, or separating layout from appearance.
---

# Godot UI from Concept

Turn a static concept into a working Godot 4 screen without painting the layout by hand. The target is a scene tree made from native controls, a theme contract that owns appearance, and a verification loop that compares the real render to the concept.

This skill is about UI reconstruction and theme architecture. For pixel fonts, AI icons, and glow, also load `godot-pixel-ui`; for generated art, load `higgsfield-game-ui`.

## When to use

Use this skill when:

- The user provides a concept image and asks for a Godot screen, screen restyle, or UI refactor.
- The work involves `Theme`, type variations, `StyleBox`, editor preview, or repeated card layouts.
- A layout must survive phone and tablet widths, a notch, or a native banner overlay.
- The user asks why a container is not sizing/centering as expected.

Do not use it for gameplay UI logic, 3D HUDs, or a single icon generation. Those belong to their own workflows.

## First: lock the contract

Before opening the scene, write down:

1. Which screens are in scope. Do not change other screens while restyling one.
2. Which product decisions are not visual: ads, resume/new behavior, removed controls, copy, and navigation.
3. Which parts of the concept are art and which are UI chrome. Chrome belongs in the theme; only illustrations belong in generated assets.
4. Which existing behavior tests encode old layout. Those tests must be updated, not silently deleted.

If the concept conflicts with an existing product rule, stop and surface the conflict before implementing.

## Workflow

### 1. Measure the concept

Record the reference viewport, outer margins, title bounds, card block, gaps, and the apparent type scale. Estimate ratios rather than copying pixels blindly:

- card width / height
- grid width / height
- content width / safe-area width
- title-to-grid and grid-to-footer spacing

Use the concept's own pixel dimensions as the design viewport. If the project uses `canvas_items`, design coordinates stay stable while the physical window scales.

### 2. Choose native containers first

Start with a `Control`-based feature screen and a small number of layout primitives:

- `MarginContainer` for outer padding and safe-area padding.
- `VBoxContainer` for vertical rhythm.
- `HBoxContainer` for one-row groupings.
- `GridContainer` for repeated cards.
- `AspectRatioContainer` to lock a whole grid or image block to one ratio.
- `CenterContainer` only when centering a child at its minimum size is actually wanted.
- `MaxWidthContainer` or an equivalent cap for tablet gutters.

Avoid a custom `Container` until a native combination demonstrably cannot express the layout. Native containers keep the editor preview and inspector useful.

See [layout recipes](references/layout-recipes.md) for tested combinations and the exact size-flag pitfalls.

### 3. Define the theme contract

Appearance belongs in theme resource files or the project theme, not in per-instance style overrides.

Use a base variation for shared behavior and child variations for variants:

```text
Button
└─ CardBase              common margins/disabled/focus
   ├─ CardVariantA       per-variant normal/hover/pressed
   ├─ CardVariantB
   ├─ CardVariantC
   └─ CardVariantD
```

Labels, status pills, and gear buttons get their own small variations. Chain a variation from another variation when the base already has the font and common state. Do not use runtime `Theme.new()` or `add_theme_stylebox_override()` for a screen that the editor should preview.

See [theme recipes](references/theme-recipes.md).

### 4. Build the scene with placeholders

Build the full hierarchy before adding final art:

1. Add the screen root and shared chrome.
2. Add the padding and responsive layout.
3. Add the title and placeholder cards.
4. Add floating controls outside containers when they are anchored.
5. Add the banner slot or other platform-owned reserved space.
6. Wire behavior only after the editor preview shows the right proportions.

Floating controls must not be children of a `MarginContainer`, `VBoxContainer`, or other `Container`: the container will lay them out. Put them under a plain `Control` root and use anchors.

### 5. Isolate screen-specific appearance

If only one screen should change:

- Put its font on screen-specific type variations; do not change the project `default_font`.
- Put its background on a screen-specific variation or child texture; do not rewrite the shared screen background.
- Keep other screens' styles untouched.
- Add a screen-specific theme variation rather than duplicating a component scene.

### 6. Make it previewable

- Use `@tool` only for components that need live editor data.
- Do not read save data in the editor. Provide an exported preview value for state that normally comes from a save file.
- Expose layout knobs (`ratio`, grid separation, paddings) in the inspector.
- Make theme variations visible in the Theme editor.
- Ensure the scene loads in the editor without `SCRIPT ERROR`.

### 7. Verify like a user

Run the real scene, not only tests:

- Render at the project design size and at 320, 375, 430, and tablet widths.
- Render all supported locales.
- Exercise hover/pressed states.
- Exercise every persisted state the screen can show: empty, active, and terminal.
- Confirm the banner slot does not overlap the floating controls.
- Check for clipping, accidental scroll, and touch targets below the project minimum.

See [verification](references/verification.md) for commands and test shapes.

## Hard rules

- No instance Theme overrides for colors, fonts, or StyleBoxes. Use theme variations.
- A `Button`'s child `PanelContainer` consumes clicks by default. Set `mouse_filter = IGNORE` on the card content, status row, pill, and labels.
- A `GridContainer` honors child size flags. A card with `SHRINK_CENTER` stays at its minimum size; use `EXPAND_FILL` on both axes.
- An `AspectRatioContainer` does not derive its own size from its ratio. Make it expand, use `STRETCH_FIT`, and align its child deliberately.
- Do not put a floating gear or FAB inside a container.
- Do not reserve banner space with a visible placeholder label. Reserve a `Control` slot and let the native ad overlay occupy it.
- A Label's height is its line height, not its font size. Measure `get_combined_minimum_size()` before hardcoding vertical spacers or offsets.
- A saved record is not automatically resumable. Derive status labels from the persisted state, not from record existence.
- Do not copy measured values from another project as a universal spec. Re-measure the new concept.
- Update old tests to the new contract. A test that asserts the old layout is not a reason to keep the old layout.

## Reference map

- [Layout recipes](references/layout-recipes.md) — tested container patterns and measured pitfalls.
- [Theme recipes](references/theme-recipes.md) — variations, per-variant states, font/background isolation.
- [Verification](references/verification.md) — screenshots, locales, state tests, commands.

## Output expectation

Leave behind:

- A scene that previews in the editor.
- Appearance in the theme, not scattered overrides.
- A screen-specific layout that survives the target widths.
- Updated tests for the new layout and behavior.
- Screenshots at the design size and at least two phone widths.
- A short note listing any deliberate deviations from the concept.
