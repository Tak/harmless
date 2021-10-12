# frozen_string_literal: true

require "reeval"
require "parsel"

module Harmless
  # Discord wrapper for regex evaluation plugin
  class REEval
    EMOTERE = /^_([^_]+)_$/
    IRCEMOTEREPLACEMENT = "\001ACTION\\1\001"
    IRCEMOTERE = /\001ACTION(.*)\001/
    MEANTRE = /^([^\s]+) (thinks [^\s]+ )?meant: /

    def initialize(harmless, bot)
      @reeval = ::REEval::REEval.new
      @harmless = harmless
      @bot = bot
    end

    def update_author_content_from_chained_replacement_header(reply_author, reply_content)
      match = reply_content.match(MEANTRE)
      if match
        [match[1], reply_content.sub(MEANTRE, "")]
      else
        [reply_author, reply_content]
      end
    end

    # Processes an incoming server message
    # * data -> discord message event
    def process_message(message)
      restrict_propagation = false
      content = preprocess_message(message.content.strip, message)
      display_name = author_display_name(message)

      if message.message.reply?
        referenced_message = message.message.referenced_message
        reply_author, reply_content = update_author_content_from_chained_replacement_header(
          author_display_name(referenced_message), preprocess_message(referenced_message.content.strip, referenced_message))
        reply_author = nil if reply_author == display_name
      end

      response = do_process_message(display_name, message.channel.name, message.channel.id, content, reply_author, reply_content) do |from, to, channel_id, text|
        restrict_propagation = true
        output_replacement(from, to, channel_id, text)
      end

      message.respond(response) if response
      restrict_propagation || response # Don't propagate if reeval reacted to a regex
    end

    # Preprocess a message
    # - Trims leading/trailing whitespace
    # - Replaces embedded IDs
    # - Replaces "emote" markup with irc emote markers
    # @param message The message to preprocess
    # @return The text of the preprocessed message
    def preprocess_message(content, message)
      Harmless.replace_ids(content, message).sub(EMOTERE, IRCEMOTEREPLACEMENT).strip
    end

    def do_process_message(author, channel_name, channel_id, content, reply_author, reply_content)
      begin
        # Allow /msg wat #sslug ledge: -1s/.*/I suck!
        parsed_channel_name, parsed_content = Parsel::Parsel.parse_channel(content)
        channel = @harmless.lookup_channel(parsed_channel_name)
        return if channel.nil?
        channel_name = channel.name
        channel_id = channel.id
        content = parsed_content
      rescue
        # Normal case
      end

      storekey = "#{author}|#{channel_name}"	# Append channel name for (some) uniqueness

      if reply_content
        @reeval.process_reply(storekey, author, content, reply_author, reply_content) do |from, to, msg|
          yield from, to, channel_id, msg unless is_empty_emote?(msg)
        end
      else
        @reeval.process_full(storekey, author, content) do |from, to, msg|
          yield from, to, channel_id, msg unless is_empty_emote?(msg)
        end
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

    private

    def author_display_name(message)
      if message.author.respond_to?(:display_name)
        message.author.display_name
      else
        message.channel.name
      end
    end

    def is_empty_emote?(text)
      match = text.match(IRCEMOTERE)
      match && match[1]&.strip&.empty?
    end
  end
end
