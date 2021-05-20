# frozen_string_literal: true

require_relative 'credentials'

module Harmless
  class RemoteControl
    MSGRE = /^MSG #([-\w]+)\s+(.*)/

    def initialize(harmless, bot)
      @harmless = harmless
      @bot = bot
      raise RuntimeError.new('Remote control password not set') unless Credentials::COMMAND_PHRASE
    end

    def process_message(message)
      text = message.content.strip
      run_command(text.sub(/^#{Credentials::COMMAND_PHRASE}\s*/, '')) if text.start_with?(Credentials::COMMAND_PHRASE)
    end

    def run_command(command)
      case command
      when 'GRUEDUMP'
        @harmless.gruedump
      when MSGRE
        if (match = command.match(MSGRE))
          @bot.servers.each_value do |server|
            puts "checking server #{server} for ##{match[1]}"
            if (channel = server.text_channels.detect { |channel| channel.name == match[1] })
              @bot.send_message(channel.id, match[2])
              return
            end
          end
        end
      end
    end
  end
end
