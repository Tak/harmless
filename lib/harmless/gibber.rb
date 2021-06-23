require "gibber"

module Harmless
  class Gibber
    CACHE = "#{ENV["HOME"]}/.gibber.yaml".freeze
    ROLLERBOT = /^([^\s]+\s+)?Roll:\s*.?\[(\d+,?\s*)+\].?\s+Result:/

    def initialize(harmless, bot)
      @gibber = ::Gibber::Gibber.new(CACHE)
      @harmless = harmless
      @bot = bot
    end

    def should_ingest(text)
      !text.match?(ROLLERBOT) # Don't ingest this garbage
    end

    def process_message(message)
      content = message.content.strip
      return false unless should_ingest(content)

      text = Harmless.replace_ids(content, message)

      if text.strip.start_with?("#{@bot.profile.username}: ")
        reply = @gibber.spew(text)
        puts "Responding: #{reply}"
        # message.respond(@gibber.spew(text))
      end
      puts "Ingesting: #{text}"
      @gibber.ingest_text(text)
      false
    end

    def dump
      @gibber.dump(CACHE)
    end
  end
end
