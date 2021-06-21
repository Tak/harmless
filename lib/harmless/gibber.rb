require "gibber"

module Harmless
  class Gibber
    CACHE = "#{ENV["HOME"]}/.gibber.yaml".freeze

    def initialize(harmless, bot)
      @gibber = ::Gibber::Gibber.new(CACHE)
      @harmless = harmless
      @bot = bot
    end

    def process_message(message)
      text = Harmless.replace_ids(message.content, message)

      if text.strip.start_with?("#{@bot.profile.username}: ")
        reply = @gibber.spew(text)
        puts "Responding: #{reply}"
        # message.reply(@gibber.spew(text))
      end
      puts "Ingesting: #{text}"
      @gibber.ingest_text(text)
    end

    def dump
      @gibber.dump(CACHE)
    end
  end
end
