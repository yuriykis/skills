# Skills

This repository contains Claude/OpenCode skills. Each skill is a folder with a required `SKILL.md` file and optional supporting files.

## Skills

- `golang-pro`: Idiomatic, version-aware Go guidance for writing and reviewing Go code.
- `software-architecture`: Backend architecture pattern guidance for layered, hexagonal, Clean Architecture, DDD, CQRS, and Event Sourcing decisions.

## Installation

Clone the repository somewhere stable. The examples below use `~/skills`; substitute any path you prefer.

```bash
git clone https://github.com/yuriykis/skills.git ~/skills
```

### Claude Code

Install globally (available in every project) by linking into `~/.claude/skills/`:

```bash
mkdir -p ~/.claude/skills
ln -sfn ~/skills/golang-pro ~/.claude/skills/golang-pro
ln -sfn ~/skills/software-architecture ~/.claude/skills/software-architecture
```

Or install per-project by linking into `.claude/skills/` inside the target repo:

```bash
mkdir -p .claude/skills
ln -sfn ~/skills/golang-pro .claude/skills/golang-pro
```

Prefer copying over symlinking? Replace `ln -sfn` with `cp -R`. Note that copies do not auto-update — you must re-copy after `git pull`.

Restart Claude Code, then verify with `/skills` or by asking "what skills are available". You should see `golang-pro` and `software-architecture`.

### OpenCode

OpenCode scans `~/.claude/skills/**/SKILL.md` by default, so the Claude Code install above already works — no extra step needed. If you prefer OpenCode-native paths, link into one of:

- `~/.config/opencode/skills/<skill>/` — global, OpenCode-native
- `.opencode/skills/<skill>/` — project-local, committed to the repo
- `~/.agents/skills/<skill>/` — alternative global path

Example, global OpenCode-native install:

```bash
mkdir -p ~/.config/opencode/skills
ln -sfn ~/skills/golang-pro ~/.config/opencode/skills/golang-pro
ln -sfn ~/skills/software-architecture ~/.config/opencode/skills/software-architecture
```

Restart OpenCode and verify by asking "list current available skills".

### Updating

Symlinked installs pick up changes automatically:

```bash
cd ~/skills && git pull
```

Copy-based installs need to be re-copied after `git pull`.

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
