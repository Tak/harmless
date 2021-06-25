require "gibber"

module Harmless
  class Gibber
    CACHE = "#{ENV["HOME"]}/.gibber.yaml".freeze
    ROLLERBOT = /^([^\s]+\s+)?Roll:\s*.?\[(\d+,?\s*)+\].?\s+Result:/
    RERE = /^\s*([^ :]+: *)?(-?\d*)?[Ss]([^\w])([^\3]*)\3([^\3]*)(\3([ginx]+|[0-9]{2}\%|))?$/
    TRRE = /^\s*([^ :]+: *)?(-?\d*)?[Tt][Rr]([^\w])([^\3]*)\3([^\3]*)(\3([0-9]{2}\%)?)?$/

    def initialize(harmless, bot)
      @gibber = ::Gibber::Gibber.new(CACHE)
      @harmless = harmless
      @bot = bot
      @user_prefix = "#{bot.profile.username}: " if bot
    end

    # Don't ingest this garbage
    def should_ingest(text)
      !text.match?(ROLLERBOT) &&
        !text.match?(RERE) &&
        !text.match?(TRRE)
    end

    def process_message(message)
      content = message.content.strip
      return false unless should_ingest(content)

      text = Harmless.replace_ids(content, message)

      # Respond to direct mentions
      message.respond(@gibber.spew(text)) if text.strip.start_with?(@user_prefix)
      puts "Ingesting: #{text}"
      @gibber.ingest_text(text)
      false
    end

    def dump
      @gibber.dump(CACHE)
    end
  end
end
