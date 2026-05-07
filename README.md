# Skills

This repository contains Claude/OpenCode skills. Each skill is a folder with a required `SKILL.md` file and optional supporting files.

## Skills

- `golang-pro`: Idiomatic, version-aware Go guidance for writing and reviewing Go code.
- `software-architecture`: Backend architecture pattern guidance for layered, hexagonal, Clean Architecture, DDD, CQRS, and Event Sourcing decisions.

## Structure

The skill folders follow Anthropic's skill packaging model:

- `SKILL.md` is required and contains YAML frontmatter plus the main instructions.
- `scripts/` is optional and contains executable helpers used only when the runtime environment supports them.
- `references/` is optional and should hold larger documentation that does not need to be loaded immediately.
- `assets/` is optional and should hold templates or other generated-output resources.

Single-file skills are valid. Extra files are only useful when they improve progressive disclosure, portability, or repeatability.

## Notes

- Do not add `README.md` inside individual skill folders; keep human-facing documentation at the repository level.
- Keep frontmatter concise: `name` must match the folder name, and `description` should say what the skill does and when to use it.
- Prefer plain instructions in `SKILL.md`; use scripts only for optional automation.
