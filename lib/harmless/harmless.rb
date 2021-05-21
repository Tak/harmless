# frozen_string_literal: true

require 'discordrb'

require_relative 'credentials'
require_relative 'grue'
require_relative 'remote_control'
require_relative 'reeval'

module Harmless
  class Harmless
    def initialize
      @bot = Discordrb::Bot.new(token: Credentials::DISCORD_TOKEN)
      puts "This bot's invite URL is #{@bot.invite_url}."
      puts 'Click on it to invite it to your server.'
      @grue = Grue.new(@bot)
      @bot.message { |message| process_message(message) }
      @consumers = {
        REEval.new(@bot) => nil,
        @grue => nil,
        RemoteControl.new(self, @bot) => nil,
      }
    end

    def process_message(message)
      @consumers.each_pair do |consumer, matcher|
        begin
          consumer.process_message(message) if !matcher || matcher(message)
        rescue => error
          puts("#{caller.first}: #{$!}\n#{error.backtrace}")
        end
      end
    end

    def gruedump
      @grue.dump
    end

    def run
      @bot.run
    end
  end
end
