#!/bin/bash

HOOKS_DIR=".git/hooks"
SOURCE_DIR=".git-hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Error: .git/hooks directory not found"
    echo ""
    echo "Please initialize git first:"
    echo "  git init"
    echo ""
    exit 1
fi

echo "📦 Installing git hooks..."
echo ""

cp "$SOURCE_DIR/commit-msg" "$HOOKS_DIR/commit-msg"
chmod +x "$HOOKS_DIR/commit-msg"
echo "  ✅ commit-msg hook installed"

cp "$SOURCE_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "  ✅ pre-commit hook installed"

echo ""
echo "✅ Git hooks installed successfully"
echo ""
echo "📋 Hooks active:"
echo "  - pre-commit: RuboCop linting on staged files"
echo "  - commit-msg: Conventional Commits validation"
echo ""
echo "📖 See CONTRIBUTING.md for complete guidelines."
echo ""
echo "Test the hooks:"
echo "  git commit --allow-empty -m \"test: verify hooks work\""
echo ""
