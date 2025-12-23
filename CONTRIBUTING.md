# Contributing to Slack Ping Bot

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Commit Message Format

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

**All commit messages are enforced via git hooks and must follow this format:**

```
type(scope): subject
```

### Type (Required)

Must be one of:

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation only changes
- **style:** Code style changes (formatting, missing semicolons, etc.)
- **refactor:** Code change that neither fixes a bug nor adds a feature
- **perf:** Performance improvement
- **test:** Adding or updating tests
- **chore:** Build process, dependencies, or auxiliary tool changes

### Scope (Optional)

Component affected by the change. Common scopes in this project:

- `ping` - Ping handling logic
- `rate-limiter` - Rate limiting functionality
- `slack-client` - Slack API wrapper
- `user-resolver` - User mention parsing
- `slack-verifier` - Request signature validation
- `logging` - Logging system
- `docs` - Documentation
- `deps` - Dependencies

**You can use any scope that makes sense.** These are just common examples.

### Subject (Required)

- Use imperative, present tense: "add" not "added" or "adds"
- Don't capitalize first letter (recommended but not enforced)
- No period (.) at the end
- Maximum 72 characters

### Breaking Changes

For commits that introduce breaking changes, suffix the type with `!`:

```
feat!(api): change authentication method
fix!(rate-limiter): remove legacy fallback mode
refactor!(logging): change logger interface
```

The `!` indicates that this commit contains breaking changes that may require users to update their code.

## Examples

### Good Commit Messages ✅

```bash
feat(ping): add support for scheduled pings
fix(rate-limiter): resolve Redis connection fallback issue
docs(readme): update installation instructions
refactor(logging): migrate from puts to Ougai
chore(deps): update sinatra to 4.2.1
test(ping-handler): add unit tests for user validation
perf(slack-client): optimize user cache lookup
style(app): fix code formatting
feat!(api): change rate limit from 3 to 5 per minute
```

### Bad Commit Messages ❌

```bash
Added new feature              # Missing type
fix: Fixed a bug               # Past tense
Update documentation.          # Missing type, has period
feat(Ping): Add feature        # Scope capitalized
update: change things          # Invalid type
```

## Development Workflow

### 1. Setup

```bash
# Clone repository
git clone <repo-url>
cd slack-ping-bot

# Install Ruby dependencies
bundle install

# Install git hooks (enforces commit format)
./git-hooks/install.sh
```

### 2. Create a Branch

```bash
# Feature branch
git checkout -b feat/your-feature-name

# Bug fix branch
git checkout -b fix/bug-description
```

Branch naming follows similar convention to commits: `type/description`

### 3. Make Changes

- Write code following existing patterns
- Use Ougai structured logging (no `puts`)
- Update documentation if needed
- Test your changes thoroughly

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional format
git commit -m "feat(ping): add scheduled ping support"
```

The git hook will validate your commit message. If invalid, you'll see an error with examples.

**Note:** The hook validates format only. You're still responsible for writing meaningful commit messages.

### 5. Push and Create PR

```bash
# Push to your branch
git push origin feat/your-feature-name

# Create pull request on GitHub
```

## Code Style

### Ruby Style

- **Ruby version:** 3.4.x
- Follow existing code patterns
- Use descriptive variable names
- Keep methods focused and short

### Logging

**Always use structured logging with Ougai:**

```ruby
# ✅ Good
logger.info("Received ping command", user_id: user_id, channel: channel)
logger.error("Failed to post message", error: e.message, channel: channel)

# ❌ Bad
puts "[INFO] Received ping from #{user_id}"
puts "Error: #{e.message}"
```

### Error Handling

Return structured hashes:

```ruby
# ✅ Good
{ success: false, error: "User not found" }
{ success: true, message: "Ping sent successfully" }

# ❌ Bad
raise "User not found"
return nil
```

### Module Patterns

Use class instances for stateful components:

```ruby
class SlackClient
  def initialize(token, logger: Ougai::Logger.new($stdout))
    @logger = logger
    # ...
  end
end
```

Use modules for stateless utilities:

```ruby
module UserResolver
  def self.resolve(channel_id, text, sender_id, slack_client)
    # ...
  end
end
```

## Testing

### Manual Testing

Before submitting your PR:

- [ ] Run application locally with your changes
- [ ] Test happy path (feature works as expected)
- [ ] Test error cases (invalid input handled gracefully)
- [ ] Check logs for errors or warnings
- [ ] Verify Redis fallback works (if applicable)

See `docs/TODO.md` for complete manual testing checklist.

### Automated Tests (Future)

Unit tests with RSpec are planned. See `docs/TODO.md` section 7.

## Pull Request Guidelines

### PR Title

Use conventional commit format:

✅ `feat(ping): add scheduled ping support`  
✅ `fix(rate-limiter): resolve Redis fallback issue`  
❌ `Add feature`  
❌ `Fix bug`  

### PR Description

Include:

1. **What changed:** Brief summary of changes
2. **Why it changed:** Motivation and context
3. **How to test:** Steps to verify the changes
4. **Screenshots:** If UI/output changes (optional)
5. **Breaking changes:** If applicable, document migration steps

### PR Size

- Keep PRs focused on one feature/fix
- Avoid combining unrelated changes
- Large features can be split into multiple PRs

### Review Process

- Address reviewer feedback promptly
- Keep discussions respectful and constructive
- Update PR based on feedback
- Squash commits if requested

## Bypassing Git Hooks

In **emergency situations only**, you can bypass the commit hook:

```bash
git commit --no-verify -m "WIP: temporary commit"
```

⚠️ **Warning:** This is for temporary local commits only. All commits in pull requests **must** follow the conventional format.

## Questions or Issues?

- **Codebase context:** See `CLAUDE.md`
- **Technical details:** See `docs/IMPLEMENTATION.md`
- **Roadmap:** See `docs/TODO.md`
- **User guide:** See `README.md`

For questions not covered in documentation, open an issue for discussion.

---

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/)
- [Ruby Style Guide](https://rubystyle.guide/)
- [Ougai Logger Documentation](https://github.com/tilfin/ougai)

---

Thank you for contributing! 🎉
