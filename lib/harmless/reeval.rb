# frozen_string_literal: true

require "reeval"
require "parsel"

module Harmless
  # Discord wrapper for regex evaluation plugin
  class REEval
    EMOTERE = /^_([^_]+)_$/
    IRCEMOTEREPLACEMENT = "\001ACTION\\1\001"
    IRCEMOTERE = /\001ACTION(.*)\001/

    def initialize(harmless, bot)
      @reeval = ::REEval::REEval.new
      @harmless = harmless
      @bot = bot
    end

    # Processes an incoming server message
    # * data -> discord message event
    def process_message(message)
      # FIXME: Doesn't work with private messages
      response = do_process_message(message.author.display_name, message.channel.name, message.channel.id,
        preprocess_message(message.content, message)) do |from, to, channel_id, text|
        output_replacement(from, to, channel_id, text)
      end

      message.respond(response) if response
    rescue
      puts("#{caller(1..1).first}: #{$!}")
    end

    # Preprocess a message
    # - Trims leading/trailing whitespace
    # - Replaces embedded IDs
    # - Replaces "emote" markup with irc emote markers
    # @param message The message to preprocess
    # @return The text of the preprocessed message
    def preprocess_message(content, message)
      Harmless.replace_ids(content.strip, message).sub(EMOTERE, IRCEMOTEREPLACEMENT).strip
    end

    def do_process_message(author, channel_name, channel_id, content)
      begin
        # Allow /msg wat #sslug ledge: -1s/.*/I suck!
        channel_name, content = Parsel::Parsel.parse_channel(content)
        channel = @harmless.lookup_channel(channel_name)
        return if channel.nil?
        channel_name = channel.name
        channel_id = channel.id
      rescue
        # Normal case
      end

      storekey = "#{author}|#{channel_name}"	# Append channel name for (some) uniqueness

      @reeval.process_full(storekey, author, content) do |from, to, msg|
        yield from, to, channel_id, msg
      end
    end

    # Sends a replacement message
    # * nick is the nick of the user who issued the replacement command
    # * tonick is the nick of the user whose text nick is replacing,
    # or nil for his own
    # * sometext is the replacement text
    def output_replacement(nick, tonick, channel, sometext)
      # TODO: ellipsize text?

      puts "#{nick} => #{tonick} '#{sometext}'"

      newtext = sometext.sub(IRCEMOTERE, '\\1')
      emote = (newtext != sometext)

      sometext = "\\* _#{tonick || nick} #{newtext}_" if emote
      sometext = if tonick
        "#{nick} thinks #{tonick} meant: #{sometext}"
      else
        "#{nick} meant: #{sometext}"
      end
      @bot.send_message(channel, sometext)
    end
  end
end
