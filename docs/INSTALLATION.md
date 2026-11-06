# Installation

The supported installation path is the [`skills` CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add lpsjor/godot-ui-skills --list
npx skills add lpsjor/godot-ui-skills
```

Requires Node.js 22.20 or later.

## Common options

```bash
# Target one detected agent
npx skills add lpsjor/godot-ui-skills -a claude-code
npx skills add lpsjor/godot-ui-skills -a cursor
npx skills add lpsjor/godot-ui-skills -a github-copilot

# Install globally for every project
npx skills add lpsjor/godot-ui-skills -g

# Install a subset
npx skills add lpsjor/godot-ui-skills --skill godot-ui-from-concept
npx skills add lpsjor/godot-ui-skills --skill godot-pixel-ui
npx skills add lpsjor/godot-ui-skills --skill higgsfield-game-ui

# Use copies instead of symlinks
npx skills add lpsjor/godot-ui-skills --copy
```

The CLI detects agents and installs each one's skills directory as a symlink to a canonical copy by default. See the [supported agents table](https://github.com/vercel-labs/skills/blob/main/docs/agents.md).

## Update

```bash
npx skills check
npx skills update
```

Updates are explicit. The CLI does not poll GitHub in the background. Start a new agent session after updating so discovery refreshes; some agents also expose a reload command.

## Local checkout

```bash
git clone https://github.com/lpsjor/godot-ui-skills.git
cd godot-ui-skills
npx skills add . --list
npx skills add .
```

## Manual fallback

If the CLI cannot detect your agent, or Node is unavailable, link or copy each skill directory. Do not link the parent `skills/` directory: the skill is the directory containing `SKILL.md`.

```bash
git clone https://github.com/lpsjor/godot-ui-skills.git ~/src/godot-ui-skills
mkdir -p ~/.agents/skills
for skill in ~/src/godot-ui-skills/skills/*/; do
  ln -s "${skill%/}" "$HOME/.agents/skills/$(basename "$skill")"
done
```

Use the directory your agent actually reads. `~/.agents/skills` is a shared convention read by several agents; Claude Code commonly uses `~/.claude/skills`, and other hosts have their own paths.

## Verify

```bash
npx skills list
```

Then ask the agent a prompt that should trigger a skill, for example:

> Rebuild this Godot screen from the concept image using native containers and theme variations.

or explicitly invoke the skill if the host supports it.

## Remove

```bash
npx skills remove godot-ui-from-concept
npx skills remove godot-pixel-ui
npx skills remove higgsfield-game-ui
```

For a manual symlink install, remove the symlink only:

```bash
rm ~/.agents/skills/godot-ui-from-concept
```
