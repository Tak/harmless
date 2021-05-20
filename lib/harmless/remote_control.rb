# frozen_string_literal: true

require 'discordrb'
require_relative 'credentials'

module Harmless
  class RemoteControl
    MSGRE = /^MSG #([-\w]+)\s+(.*)/
    DELETERE = /^DELETE #([-\w]+)\s+(\d+)/

    MESSAGE_LOOKUP_COUNT = 20

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

      when DELETERE
        if (match = command.match(DELETERE))
          messageIndex = match[2].to_i
          myMessageCount = 0
          raise RuntimeError.new("Invalid message index #{messageIndex}") if messageIndex < 0 || messageIndex > MESSAGE_LOOKUP_COUNT
          if (channel = lookup_channel(match[1]))
            channel.history(MESSAGE_LOOKUP_COUNT).each do |message|
              myMessageCount += 1 if message.author.id == @bot.profile.id
              if myMessageCount > messageIndex
                puts "Deleting: #{message.content}"
                channel.delete_message(message.id)
                return
              end
            end
          end
        end

      when MSGRE
        if (match = command.match(MSGRE))
          if (channel = lookup_channel(match[1]))
            @bot.send_message(channel.id, match[2])
          end
        end

      end
    end # run_command

    def lookup_channel(name)
      @bot.servers.each_value do |server|
        # puts "checking server #{server} for ##{name}"
        if (channel = server.text_channels.detect { |channel| channel.name == name })
          return channel
        end
      end
    end
  end
end
