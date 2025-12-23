# Git Hooks

This directory contains git hooks for enforcing project standards.

## Overview

**pre-commit** - Validates Ruby code quality with RuboCop before commit.

**commit-msg** - Validates commit messages against [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.

## Installation

After cloning or initializing the repository:

```bash
./git-hooks/install.sh
```

This copies hooks from `.git-hooks/` to `.git/hooks/` and makes them executable.

## Validation Rules

### RuboCop Linting

**Enforces:**
- Single quotes for strings (double for interpolation)
- 120 character line length
- Code style consistency
- Performance best practices
- No code comments

**Auto-fix violations:**
```bash
bundle exec rubocop -A path/to/file.rb
```

**Bypass pre-commit (emergency only):**
```bash
git commit --no-verify
```

### Conventional Commits

**Valid Formats**

```
type(scope): subject
type!(scope): subject  (breaking change)
```

**Examples:**
```bash
git commit -m "feat(ping): add scheduled ping support"
git commit -m "fix(rate-limiter): resolve Redis fallback"
git commit -m "feat!(api): change rate limit to 5 per minute"
git commit -m "docs: update installation instructions"
```

### Invalid Formats

```bash
git commit -m "Added feature"              # Missing type
git commit -m "feat add feature"           # Missing colon
git commit -m "update: change something"   # Invalid type
```

## Bypass Hooks (Emergency Only)

```bash
git commit --no-verify -m "WIP: temp commit"
```

⚠️ **Warning:** Only use `--no-verify` for temporary local commits. All PR commits must pass both hooks.

## Troubleshooting

**Hooks not working?**

```bash
# Check hooks exist
ls -l .git/hooks/pre-commit
ls -l .git/hooks/commit-msg

# Reinstall
./git-hooks/install.sh

# Test commit-msg directly
echo "feat: test" | .git/hooks/commit-msg /dev/stdin

# Test pre-commit directly
git add file.rb
.git/hooks/pre-commit
```

## Reference

- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- See `CONTRIBUTING.md` for complete guidelines
