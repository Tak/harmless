# frozen_string_literal: true

require "grue"

module Harmless
  # Discord wrapper for url repost shaming
  class Grue
    def initialize(bot)
      @bot = bot
      @grue = ::Grue::Grue.new
      @grue.load
    end

    def process_message(message)
      nick = message.author.display_name
      response = @grue.process_statement("##{message.channel.name}", nick, message.content.strip)
      output_shame(message.channel.id, nick, response) if response && response.size > 1
    end

    # Sends a shaming message
    # * nick is the nick of the user who sent the duplicate url
    # * results are the results of the lookup
    def output_shame(channel, nick, results)
      originick = results[0][1]
      duration_text = ::Grue.pretty_print_duration_difference(results[0][2], Time.now)
      duplicates = results.size - 2

      sometext = if originick.casecmp(nick).zero?
        "#{nick} just grued its own link from #{duration_text} ago!"
      else
        "#{nick} just grued #{originick}'s link from #{duration_text} ago!"
      end
      sometext += " (#{duplicates} duplicates)" if duplicates.positive?

      @bot.send_message(channel, sometext)
    end

    def dump
      @grue.dump
    end
  end
end
