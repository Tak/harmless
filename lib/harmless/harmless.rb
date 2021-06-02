# frozen_string_literal: true

require "discordrb"

require_relative "credentials"
require_relative "grue"
require_relative "remote_control"
require_relative "reeval"

module Harmless
  # Discord bot that integrates a bunch of small message reaction functionalities
  class Harmless
    MESSAGE_LOOKUP_COUNT = 20

    def initialize
      @bot = Discordrb::Bot.new(token: Credentials::DISCORD_TOKEN)
      puts "This bot's invite URL is #{@bot.invite_url}."
      puts "Click on it to invite it to your server."
      @grue = Grue.new(@bot)
      @bot.message { |message| process_message(message) }
      @consumers = {
        REEval.new(self, @bot) => nil,
        @grue => nil,
        RemoteControl.new(self, @bot) => nil
      }
    end

    def process_message(message)
      @consumers.each_pair do |consumer, matcher|
        consumer.process_message(message) if !matcher || matcher(message)
      rescue => error
        puts("#{caller(1..1).first}: #{$!}\n#{error.backtrace}")
      end
    end

    def gruedump
      @grue.dump
    end

    def run
      @bot.run
    end

    # Look up a channel
    # @param name The name of the desired channel
    # @return The first channel on connected servers matching name
    # @raise When no matching channel is found
    def lookup_channel(name)
      @bot.servers.each_value do |server|
        if (channel = server.text_channels.detect { |channel| channel.name == name })
          return channel
        end
      end
      raise "Failed to look up channel '##{name}'"
    end

    # Look up a message
    # @param channel The Channel instance to search for the message
    # @param message_index The (0-based) index of the message to be found
    # @param validator A predicate proc to be applied to messages to determine whether they should be considered
    # @yield The messageIndexth message matching validator
    def lookup_message(channel, message_index, validator)
      message_count = 0
      channel.history(MESSAGE_LOOKUP_COUNT).each do |message|
        message_count += 1 if validator.call(message)
        next unless message_count > message_index

        yield message
        break
      end
    end
  end
end
