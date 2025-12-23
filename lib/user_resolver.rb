# frozen_string_literal: true

module UserResolver
  # Resolve target user from command context
  # Returns { user_id:, error: } hash
  def self.resolve(channel_id, text, sender_id, slack_client)
    # Case 1: DM usage - /ping (no text)
    if text.empty?
      return resolve_dm(channel_id, sender_id)
    end

    # Case 2: Channel mention - /ping @username or /ping <@U12345>
    resolve_mention(text, sender_id, slack_client)
  end

  private

  # Resolve target in DM context
  def self.resolve_dm(channel_id, sender_id)
    # In Slack, DM channels start with 'D'
    unless channel_id.start_with?("D")
      return { error: "Usage: /ping @username (in channel) or /ping (in DM)" }
    end

    # In DMs, channel_id IS the user_id of the other person
    # But since it's a DM, target should be the channel itself
    { user_id: channel_id }
  end

  # Resolve target from @mention or <@userid>
  def self.resolve_mention(text, sender_id, slack_client)
    # Extract user mention from text
    # Slack formats: @username or <@U12345> or <@U12345|username>
    
    # Pattern 1: <@U12345> or <@U12345|username>
    if text.match?(/<@([A-Z0-9]+)(\|[^>]+)?>/)
      user_id = text.match(/<@([A-Z0-9]+)/)[1]
      return validate_user(user_id, sender_id, slack_client, by_id: true)
    end

    # Pattern 2: @username (plain text)
    if text.match?(/^@?(\S+)$/)
      username = text.gsub(/^@/, "")
      return resolve_username(username, sender_id, slack_client)
    end

    { error: "Invalid format. Usage: /ping @username" }
  end

  # Resolve username to user_id
  def self.resolve_username(username, sender_id, slack_client)
    user = slack_client.get_user_by_name(username)

    if user.nil?
      return { error: "User @#{username} not found. Use exact username or <@userid> format." }
    end

    validate_user(user["id"], sender_id, slack_client, by_id: false)
  end

  # Validate user is pingable
  def self.validate_user(user_id, sender_id, slack_client, by_id: false)
    # Get user info if we only have ID
    if by_id
      user = slack_client.get_user_by_id(user_id)
      if user.nil?
        return { error: "User not found." }
      end
    else
      user = slack_client.get_user_by_id(user_id)
    end

    # Check 1: Cannot ping yourself
    if user_id == sender_id
      return { error: "You cannot ping yourself." }
    end

    # Check 2: Cannot ping bots
    if user["is_bot"]
      return { error: "You cannot ping bots or apps." }
    end

    # Check 3: Cannot ping deactivated users
    if user["deleted"]
      return { error: "Cannot ping deactivated users." }
    end

    # All checks passed
    { user_id: user_id }
  end
end
