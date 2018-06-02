# Helper methods for abusing reactions :'(
module Reactions
  RATE_LIMIT = 0.25

  # Manually issues a reaction request
  def self.react(message, reaction)
    channel_id = message.channel.id
    message_id = message.id
    encoded_reaction = URI.encode(reaction)

    RestClient.put(
      "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/#{encoded_reaction}/@me",
      nil,
      Authorization: SHRK.token
    )
  end

  # Applies multiple reactions at the given `RATE_LIMIT`
  def self.spam_reactions(message, reactions)
    reactions.each do |r|
      react(message, r)
      sleep RATE_LIMIT
    end
  end

  # Shortcut method
  def self.confirm(message)
    react(message, Emojis.name_to_unicode('checkmark'))
  end

  # Shortcut method
  def self.error(message)
    react(message, Emojis.name_to_unicode('crossmark'))
  end

  # Used to put an accept / decline dialog on a message. Gets the user that the prompt is for.
  # Returns true / false depending on input, or nil if no choice was made.
  # Staff users (permission level 1) are also able to make the choice.
  def self.yes_no(message, user)
    choice = nil

    SHRK.add_await(:"yes_no_#{message.id}", Discordrb::Events::ReactionAddEvent) do |r_event|
      # Only the user who sent the message and staff should be abled to confirm / deny.
      next false unless (r_event.message.id == message.id) && (r_event.user.id == user.id || SHRK.permission?(event.user, 1, event.server))
      choice = false if r_event.emoji.name == Emojis.name_to_emoji('crossmark')
      choice = true if r_event.emoji.name == Emojis.name_to_emoji('checkmark')

      next false if choice.nil?
    end
    spam_reactions(message, [Emojis.name_to_emoji('checkmark'), Emojis.name_to_emoji('crossmark')])

    # Timeout
    i = 30
    loop do
      if i.zero?
        SHRK.awaits.delete(:"yes_no_#{message.id}")
        return nil
      elsif choice.nil?
        i -= 1
        sleep 1
      else
        return choice
      end
    end
  end
end
