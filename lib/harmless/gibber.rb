require "gibber"

module Harmless
  class Gibber
    CACHE = "#{ENV["HOME"]}/.gibber.yaml".freeze
    ROLLERBOT = /^([^\s]+\s+)?Roll:\s*.?\[(\d+,?\s*)+\].?\s+Result:/
    RERE = /^\s*([^ :]+: *)?(-?\d*)?[Ss]([^\w])([^\3]*)\3([^\3]*)(\3([ginx]+|[0-9]{2}\%|))?$/
    TRRE = /^\s*([^ :]+: *)?(-?\d*)?[Tt][Rr]([^\w])([^\3]*)\3([^\3]*)(\3([0-9]{2}\%)?)?$/
    EMOTERE = /^_(.*)_$/
    SPOILERRE = /\|\|([^|]+)\|\|/
    FORMATRE = /(_|\*|\*\*|\*\*\*|~~)([^\s*~_].*?\s[^\s*~_].*?)\1/
    QUOTERE = /^>\s+/

    attr_accessor :response_period

    def initialize(harmless, bot, response_period = 100)
      @gibber = ::Gibber::Gibber.new(CACHE)
      @harmless = harmless
      @bot = bot
      @response_period = response_period
      @seen_messages = 0
    end

    # Don't ingest this garbage
    def should_ingest(text)
      !text.match?(ROLLERBOT) &&
        !text.match?(RERE) &&
        !text.match?(TRRE)
    end

    def user_prefix
      if @user_prefix
        @user_prefix
      elsif @bot
        @user_prefix = "#{@bot.profile.username}: "
      end
    end

    def should_respond(text, response_period, seen_messages)
      (user_prefix && text.strip.start_with?(user_prefix)) || # direct mentions
        (response_period > 0 && (rand(response_period - seen_messages) == 1)) # periodicity
    end

    def respond_to(text, message)
      spew = @gibber.spew(text)
      3.times do
        # try up to 3 times to send response
        message.respond(spew)
        @seen_messages = 0
        return
      rescue
        sleep(1)
      end
    end

    def preprocess_text(text)
      if (match = text.match(EMOTERE)) # whole-message emotes (TODO: special-case emote message type)
        text = match[1]
      end
      text = text.gsub(QUOTERE, "") # > quote goes here
      while (match = text.match(FORMATRE))
        text = text.sub(FORMATRE,
          match[2].split.collect do |token|
            "#{match[1]}#{token}#{match[1]}"
          end.join(" ")) # _foo bar baz_ => _foo_ _bar_ _baz_
      end
      text.gsub(SPOILERRE, "\\1") # strip spoiler sections (TODO: separate storage for sensitive urls?)
    end

    def process_message(message)
      text = Harmless.replace_ids(message.content.strip, message)
      return false unless should_ingest(text)

      @seen_messages += 1
      text = preprocess_text(text)
      respond_to(text, message) if should_respond(text, @response_period, @seen_messages)
      puts "Ingesting: #{text}"
      @gibber.ingest_text(text)
      false
    end

    def dump
      @gibber.dump(CACHE)
    end
  end
end
