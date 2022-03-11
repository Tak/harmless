require "cronk"

module Harmless
  class Cronk
    def initialize
      @cronk = ::Cronk::Cronk.new
    end

    def schedule(first, interval, &block)
      @cronk.schedule(first, interval, &block)
    end

    # Received message callback
    def process_message(message)
      @cronk.run_tasks
    end
  end
end
