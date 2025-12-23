# Git Hooks

This directory contains git hooks for enforcing project standards.

## Overview

**commit-msg** - Validates commit messages against [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.

## Installation

After cloning or initializing the repository:

```bash
./git-hooks/install.sh
```

This copies hooks from `.git-hooks/` to `.git/hooks/` and makes them executable.

## Validation Rules

### Valid Formats

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

## Bypass Hook (Emergency Only)

```bash
git commit --no-verify -m "WIP: temp commit"
```

⚠️ **Warning:** Only use `--no-verify` for temporary local commits. All PR commits must follow the format.

## Troubleshooting

**Hook not working?**

```bash
# Check hook exists
ls -l .git/hooks/commit-msg

# Reinstall
./git-hooks/install.sh

# Test directly
echo "feat: test" | .git/hooks/commit-msg /dev/stdin
```

## Reference

- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- See `CONTRIBUTING.md` for complete guidelines
