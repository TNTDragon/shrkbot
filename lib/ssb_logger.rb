# Allows to send log messages in a dedicated log channel (varies per server)
class SSBLogger
  def log(server, message)
    log_channel = get_log_channel(server.id)

    unless log_channel
      # Format message as code, to distinguish between the original and the added warning message.
      message.prepend('```') << '```'
      # Add a warning message.
      message << "\nCouldn't find a log channel to log this message to on \"#{server.name}.\" "
      message << 'Please set one using `.setLogChannel <channelName>` on that server.'
      pm_owner(server, message)
      return
    end

    SSB.channel(log_channel).send_message(message)
  end

  def pm_owner(server, message)
    server.owner.pm(message)
  end

  def default_log_channel(server)
    # Don't do anything if there's already a log channel.
    return if get_log_channel(server.id)
    # Log channel defaults to whatever convenient, ideally non-public channel it can find.
    log_channel = server.channels.find { |channel| channel.name =~ /(mod|admin|staff|log)/i }

    DB.unique_insert("ssb_server_#{server.id}".to_sym, :log_channel, log_channel&.id)

    # Let people on the server know what the log channel is.
    message = 'Set this channel as log channel. Future log messages will be sent here. '
    message << ' You can change it by using `.setLogChannel <channelName>`.' if log_channel
    log(server, message)
  end

  private

  def get_log_channel(server_id)
    DB.read_value("ssb_server_#{server_id}".to_sym, :log_channel)
  end
end
