# frozen_string_literal: true

module UserResolver
  def self.resolve(channel_id, text, sender_id, slack_client)
    return resolve_dm(channel_id, sender_id) if text.empty?

    resolve_mention(text, sender_id, slack_client)
  end

  def self.resolve_dm(channel_id, _sender_id)
    return { error: 'Usage: /ping @username (in channel) or /ping (in DM)' } unless channel_id.start_with?('D')

    { user_id: channel_id }
  end

  def self.resolve_mention(text, sender_id, slack_client)
    if text.match?(/<@([A-Z0-9]+)(\|[^>]+)?>/)
      user_id = text.match(/<@([A-Z0-9]+)/)[1]
      return validate_user(user_id, sender_id, slack_client, by_id: true)
    end

    if text.match?(/^@?(\S+)$/)
      username = text.gsub(/^@/, '')
      return resolve_username(username, sender_id, slack_client)
    end

    { error: 'Invalid format. Usage: /ping @username' }
  end

  def self.resolve_username(username, sender_id, slack_client)
    user = slack_client.get_user_by_name(username)

    return { error: "User @#{username} not found. Use exact username or <@userid> format." } if user.nil?

    validate_user(user['id'], sender_id, slack_client, by_id: false)
  end

  def self.validate_user(user_id, sender_id, slack_client, by_id: false)
    user = slack_client.get_user_by_id(user_id)
    return { error: 'User not found.' } if by_id && user.nil?

    return { error: 'You cannot ping yourself.' } if user_id == sender_id

    return { error: 'You cannot ping bots or apps.' } if user['is_bot']

    return { error: 'Cannot ping deactivated users.' } if user['deleted']

    { user_id: user_id }
  end
end
