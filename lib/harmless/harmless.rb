# frozen_string_literal: true

require 'discordrb'
require 'reeeeeee'

require_relative 'credentials'
require_relative 'grue'

module Harmless
  class Harmless
    def initialize
      @bot = Discordrb::Bot.new(token: Credentials::DISCORD_TOKEN)
      puts "This bot's invite URL is #{@bot.invite_url}."
      puts 'Click on it to invite it to your server.'
      @bot.message { |message| process_message(message) }
      @consumers = {
        Reeeeeee::Reeeeeee.new(@bot) => nil,
        Grue.new(@bot) => nil,
      }
    end

    def process_message(message)
      @consumers.each_pair do |consumer, matcher|
        begin
          consumer.process_message(message) if !matcher || matcher(message)
        rescue
          puts("#{caller.first}: #{$!}")
        end
      end
    end

    def run
      @bot.run
    end
  end
end
