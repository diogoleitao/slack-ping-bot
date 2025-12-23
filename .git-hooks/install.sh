#!/bin/bash
# Install git hooks for conventional commits validation

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

echo "✅ Git hooks installed successfully"
echo ""
echo "📋 Commit messages will now be validated against Conventional Commits format."
echo "📖 See CONTRIBUTING.md for complete guidelines."
echo ""
echo "Test the hook:"
echo "  git commit --allow-empty -m \"test: verify hook works\""
