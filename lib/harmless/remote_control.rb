# frozen_string_literal: true

require 'discordrb'
require_relative 'credentials'

module Harmless
  # Allow limited remote control of the bot
  class RemoteControl
    MSGRE = /^MSG #([-\w]+)\s+(.*)/.freeze
    DELETERE = /^DELETE #([-\w]+)\s+(\d+)/.freeze

    MESSAGE_LOOKUP_COUNT = 20

    # @param harmless The plugin instance
    # @param bot The discordrb bot instance
    def initialize(harmless, bot)
      @harmless = harmless
      @bot = bot
      raise 'Remote control password not set' unless Credentials::COMMAND_PHRASE
    end

    # Received message callback
    def process_message(message)
      text = message.content.strip
      response = run_command(text.sub(/^#{Credentials::COMMAND_PHRASE}\s*/, '')) if text.start_with?(Credentials::COMMAND_PHRASE)
      message.send_message(response) if response
    end

    # Execute a command string
    # @param command A command string, e.g. 'MSG #sslug whatever'
    def run_command(command)
      case command
      when 'GRUEDUMP'
        @harmless.gruedump
        return 'Dumped grue database'

      when DELETERE
        if (match = command.match(DELETERE))
          messageIndex = match[2].to_i
          myMessageCount = 0
          raise "Invalid message index #{messageIndex}" if messageIndex.negative? || messageIndex > MESSAGE_LOOKUP_COUNT

          if (channel = lookup_channel(match[1]))
            channel.history(MESSAGE_LOOKUP_COUNT).each do |message|
              myMessageCount += 1 if message.author.id == @bot.profile.id
              next unless myMessageCount > messageIndex

              channel.delete_message(message.id)
              return "Deleted: #{message.content} from ##{channel.name} on #{channel.server.name}"
            end
          end
        end

      when MSGRE
        if (match = command.match(MSGRE)) && (channel = lookup_channel(match[1]))
          @bot.send_message(channel.id, match[2])
        end

      end
      nil
    end

    def lookup_channel(name)
      @bot.servers.each_value do |server|
        if (channel = server.text_channels.detect { |channel| channel.name == name })
          return channel
        end
      end
    end
  end
end
