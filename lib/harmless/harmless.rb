# frozen_string_literal: true

require "discordrb"

require_relative "credentials"
require_relative "grue"
require_relative "remote_control"
require_relative "reeval"
require_relative "gibber"

module Harmless
  # Discord bot that integrates a bunch of small message reaction functionalities
  class Harmless
    MESSAGE_LOOKUP_COUNT = 20
    NICKRE = /<@!?(\d+)>/
    CHANNELIDRE = /<#(\d+)>/

    def initialize
      @bot = Discordrb::Bot.new(token: Credentials::DISCORD_TOKEN)
      puts "This bot's invite URL is #{@bot.invite_url}."
      puts "Click on it to invite it to your server."
      @grue = Grue.new(@bot)
      @gibber = Gibber.new(self, @bot, 0) # disable periodic autoresponse for now
      @bot.message { |message| process_message(message) }
      @consumers = [
        [RemoteControl.new(self, @bot), nil],
        [REEval.new(self, @bot), nil],
        [@grue, nil],
        [@gibber, nil]
      ]
    end

    def process_message(message)
      @consumers.each do |pair|
        consumer = pair[0]
        matcher = pair[1]
        if !matcher || matcher(message)
          break if consumer.process_message(message)
        end
      rescue => error
        puts("#{caller(1..1).first}: #{$!}\n#{error.backtrace}")
      end
    end

    def gruedump
      @grue.dump
    end

    def gibberdump
      @gibber.dump
    end

    def gibber_period(period)
      @gibber.response_period = period
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

    # Replace embedded discord IDs with names
    def self.replace_ids(text, message)
      text = text.scan(CHANNELIDRE).inject(text) do |input, id|
        if (channel = message.server&.text_channels&.detect { |channel| channel.id == id[0] })
          input.sub(/<##{id[0]}>/, "##{channel.name}")
        else
          input
        end
      end
      text.scan(NICKRE).inject(text) do |input, id|
        if (member = message.server&.member(id[0].to_i))
          input.sub(/<@!?#{id[0]}>/, "#{member.display_name}:")
        else
          input
        end
      end
    end
  end
end
