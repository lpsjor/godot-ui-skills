# Contributing

## License

By contributing, you agree that your contribution is licensed under the MIT License in this repository.

## Add or change a skill

Each skill is one directory under `skills/`:

```text
skills/<skill-name>/
├─ SKILL.md
├─ references/
└─ scripts/
```

The directory name must equal the frontmatter `name`. Names must be lowercase ASCII letters, digits, and single hyphens.

Use only the portable frontmatter core:

```yaml
---
name: my-skill
description: What the skill does and when to use it. Include the symptoms, files, APIs, and user phrases that should trigger it.
---
```

Do not add host-specific frontmatter (`globs`, `paths`, `hide`, `enabled`, `allowed-tools`) to committed skills. Put host-specific presentation in `references/` if it is genuinely useful.

## Content rules

- `SKILL.md` is an operational playbook, not an encyclopedia. Keep it under 500 lines and move depth to `references/`.
- Link every reference directly from `SKILL.md` and say when to read it.
- Use relative paths from the skill directory. The skill must work after its directory is copied alone.
- Scripts must have a clear CLI, fail non-zero on invalid input, avoid network and destructive defaults, and write only to explicit output paths.
- Do not commit game assets, generated binaries, credentials, or proprietary concept art.
- Prefer native Godot behavior over custom containers, runtime theme construction, or instance theme overrides.
- When documenting a project-specific case, label it as a case study and keep the reusable rule separate.

## Validate

```bash
python3 scripts/validate_skills.py
```

The validator checks directory/name agreement, the minimal frontmatter, description and body limits, duplicate names, and relative links.
