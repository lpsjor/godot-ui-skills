# godot-ui-skills

Godot 4 UI reconstruction skills for AI coding agents.

These are portable [`SKILL.md`](https://agentskills.io/specification) packages that teach an agent how to turn a concept screen into native Godot `Control`/`Container` scenes, a theme-driven visual contract, pixel typography, and an asset pipeline that stays editable in the editor.

They are instructions and small scripts, not a Godot add-on. Nothing is added to your game at runtime.

## Install

Requires Node.js 22.20 or later.

```bash
# Preview what will be installed
npx skills add lpsjor/godot-ui-skills --list

# Install into the agents detected on this machine
npx skills add lpsjor/godot-ui-skills

# Install globally for every project
npx skills add lpsjor/godot-ui-skills -g

# Install one skill only
npx skills add lpsjor/godot-ui-skills --skill godot-ui-from-concept
```

From a local checkout:

```bash
cd godot-ui-skills
npx skills add . --list
npx skills add .
```

The skills CLI installs each agent's skills directory as a symlink to one canonical copy by default. Add `--copy` if you need independent files.

### Update

```bash
npx skills check
npx skills update
```

There is no automatic update. Restart or start a new agent session after updating so skill discovery refreshes.

### Pin a release

To avoid silently following `main`, pin a release tag:

```bash
npx skills add lpsjor/godot-ui-skills@v0.1.0
```

### Manual fallback

For agents the CLI does not detect, or environments without Node, link the skill folders directly. Each folder under `skills/` is one complete skill.

```bash
git clone https://github.com/lpsjor/godot-ui-skills.git ~/src/godot-ui-skills
mkdir -p ~/.agents/skills
for skill in ~/src/godot-ui-skills/skills/*/; do
  ln -s "${skill%/}" "$HOME/.agents/skills/$(basename "$skill")"
done
```

The shared `~/.agents/skills` location is read by several agents. For agent-specific paths, see the [skills CLI supported agents](https://github.com/vercel-labs/skills/blob/main/docs/agents.md). This fallback is provided for convenience; the supported installation path is `npx`.

## Skills

| Skill | Use it for |
|---|---|
| [`godot-ui-from-concept`](skills/godot-ui-from-concept/SKILL.md) | Rebuilding a mockup in Godot with native containers, theme variations, editor-previewable layout, and real verification. |
| [`godot-pixel-ui`](skills/godot-pixel-ui/SKILL.md) | Pixel fonts, CJK subsets, opaque-core icon centering, 9-patch neon glow, and fractionally scaled pixel UI. |
| [`higgsfield-game-ui`](skills/higgsfield-game-ui/SKILL.md) | Generating game UI icon sheets, sprites, and starfields with Higgsfield, then slicing and cleaning them for Godot. |

A router is intentionally not included while the collection is this small. Add one only when the trigger surface becomes ambiguous.

## Requirements

- Godot 4.7 or later for the layout and verification workflows.
- Node.js 22.20 or later for `npx skills`.
- Python 3.10 or later for the repository validator (CI only).
- Higgsfield CLI only when using `higgsfield-game-ui`; see `skill://higgsfield-generate`.

The scripts are optional. Every workflow can be completed manually with the editor and command line.

## Repository layout

```text
skills/<skill-name>/
├─ SKILL.md
├─ references/
└─ scripts/
```

Each skill is self-contained and uses only relative paths. The repository deliberately keeps `SKILL.md` frontmatter to the portable core:

```yaml
---
name: skill-name
description: What it does and when to use it.
---
```

Repository licensing, versioning, and CI live outside the skill folders.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Run:

```bash
python3 scripts/validate_skills.py
```

## License

MIT. See [LICENSE](LICENSE).

This project is not affiliated with the Godot Foundation. Godot is a trademark of the Godot Foundation.
