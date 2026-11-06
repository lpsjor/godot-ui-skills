#!/usr/bin/env python3
"""Validate the portable core of every skill in this repository."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
REQUIRED_KEYS = {"name", "description"}

errors: list[str] = []
warnings: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def parse_frontmatter(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail(f"{path}: missing opening frontmatter fence")
        return {}, text
    end = text.find("\n---", 4)
    if end < 0:
        fail(f"{path}: missing closing frontmatter fence")
        return {}, text
    block = text[4:end]
    body = text[end + 4 :].lstrip("\n")
    data: dict[str, str] = {}
    for raw in block.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            fail(f"{path}: invalid frontmatter line: {raw!r}")
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key in data:
            fail(f"{path}: duplicate frontmatter key {key!r}")
        data[key] = value
    return data, body


def check_links(path: Path, body: str) -> None:
    skill_dir = path.parent.resolve()
    for raw in LINK_RE.findall(body):
        target = raw.strip()
        if not target:
            continue
        if target.startswith(("http://", "https://", "mailto:", "#", "skill://")):
            continue
        target = target.split("#", 1)[0].strip()
        if not target:
            continue
        candidate = (skill_dir / target).resolve()
        try:
            candidate.relative_to(skill_dir)
        except ValueError:
            fail(f"{path}: link escapes the skill directory: {target}")
            continue
        if not candidate.exists():
            fail(f"{path}: missing link target: {target}")


def main() -> int:
    if not SKILLS.is_dir():
        fail("missing skills/ directory")
    if not (ROOT / "LICENSE").is_file():
        fail("missing LICENSE")
    if not (ROOT / "README.md").is_file():
        fail("missing README.md")

    found: dict[str, Path] = {}
    for path in sorted(SKILLS.rglob("SKILL.md")):
        if not path.is_file():
            continue
        relative = path.relative_to(SKILLS)
        dir_name = path.parent.name
        data, body = parse_frontmatter(path)

        if set(data) != REQUIRED_KEYS:
            fail(f"{path}: frontmatter must contain exactly name and description (got {sorted(data)})")
        name = data.get("name", "")
        description = data.get("description", "")
        if not NAME_RE.fullmatch(name):
            fail(f"{path}: invalid name {name!r}")
        if name != dir_name:
            fail(f"{path}: name {name!r} does not match directory {dir_name!r}")
        if not description:
            fail(f"{path}: empty description")
        elif len(description) > 1024:
            fail(f"{path}: description is {len(description)} characters; max 1024")
        if name in found:
            fail(f"{path}: duplicate skill name {name!r} (also {found[name]})")
        else:
            found[name] = path

        line_count = len(body.splitlines())
        if line_count > 500:
            fail(f"{path}: body is {line_count} lines; keep SKILL.md under 500")
        elif line_count > 400:
            warnings.append(f"{path}: body is {line_count} lines; consider moving detail to references")

        check_links(path, body)

    if not found:
        fail("no skills found")
    else:
        print(f"validated {len(found)} skills: {', '.join(sorted(found))}")

    for warning in warnings:
        print(f"warning: {warning}")
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    if errors:
        print(f"FAILED with {len(errors)} error(s)", file=sys.stderr)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
