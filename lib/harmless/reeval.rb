# frozen_string_literal: true

require 'reeval'

module Harmless
  class REEval
    CHANNELRE = /^#[-\w\d]+$/
    NICKRE = /<@!?(\d+)>/
    CHANNELIDRE = /<#(\d+)>/
    EMOTERE = /^_(.+)_$/

    def initialize(bot)
      @reeval = ::REEval::REEval.new
      @bot = bot
    end

    # Processes an incoming server message
    # * data -> discord message event
    def process_message(message)
      begin
        # FIXME: Doesn't work with private messages
        mynick = message.author.display_name
        channel = message.channel
        content = message.content.strip

        puts("Processing message: #{mynick}|#{channel.name}: #{content}")
        newcontent = replace_ids(message)
        puts("Postprocessed message: #{mynick}|#{channel.name}: #{newcontent}") if newcontent != content
        content = newcontent

        if (matches = content.match(CHANNELRE))
          # Allow /msg wat #sslug ledge: -1s/.*/I suck!
          content = content.sub(CHANNELRE, '').strip
          channel = message.server.text_channels.detect{ |channel| channel.name == matches[0] }
          return if channel == nil
        end
        storekey = "#{mynick}|#{channel.name}"	# Append channel name for (some) uniqueness

        response = @reeval.process_full(storekey, mynick, content) do |from, to, msg|
          output_replacement(from, to, channel.id, msg)
        end

        message.respond(response) if response
      rescue
        puts("#{caller.first}: #{$!}")
      end
    end # process_message

    # Sends a replacement message
    # * nick is the nick of the user who issued the replacement command
    # * tonick is the nick of the user whose text nick is replacing,
    # or nil for his own
    # * sometext is the replacement text
    def output_replacement(nick, tonick, channel, sometext)
      # TODO: ellipsize text?

      puts "#{nick} => #{tonick} '#{sometext}'"

      newtext = sometext.sub(EMOTERE, '\\1')
      emote = (newtext != sometext)

      if tonick
        sometext = "\\* _#{tonick} #{newtext}_" if emote
        sometext = "#{nick} thinks #{tonick} meant: #{sometext}"
      else
        sometext = "\\* _#{nick} #{newtext}_" if emote
        sometext = "#{nick} meant: #{sometext}"
      end
      @bot.send_message(channel, sometext)
    end # output_replacement

    def replace_ids(message)
      text = message.content.strip
      text = text.scan(CHANNELIDRE).inject(text) do |input,id|
        if (channel = message.server.text_channels.detect{ |channel| channel.id == id[0] })
          input.sub(/<##{id[0]}>/, "##{channel.name}")
        else
          input
        end
      end
      text.scan(NICKRE).inject(text) do |input,id|
        if (member = message.server.member(id[0].to_i))
          input.sub(/<@!?#{id[0]}>/, "#{member.display_name}:")
        else
          input
        end
      end
    end
  end
end
