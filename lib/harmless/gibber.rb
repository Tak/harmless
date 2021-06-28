require "gibber"

module Harmless
  class Gibber
    CACHE = "#{ENV["HOME"]}/.gibber.yaml".freeze
    ROLLERBOT = /^([^\s]+\s+)?Roll:\s*.?\[(\d+,?\s*)+\].?\s+Result:/
    RERE = /^\s*([^ :]+: *)?(-?\d*)?[Ss]([^\w])([^\3]*)\3([^\3]*)(\3([ginx]+|[0-9]{2}\%|))?$/
    TRRE = /^\s*([^ :]+: *)?(-?\d*)?[Tt][Rr]([^\w])([^\3]*)\3([^\3]*)(\3([0-9]{2}\%)?)?$/

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
      @seen_messages = 0
      message.respond(@gibber.spew(text))
    end

    def process_message(message)
      text = Harmless.replace_ids(message.content.strip, message)
      return false unless should_ingest(text)

      @seen_messages += 1
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
