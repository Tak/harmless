# frozen_string_literal: true

require "discordrb"
require "parsel"

require_relative "credentials"

module Harmless
  # Allow limited remote control of the bot
  class RemoteControl
    # Each entry must correspond to an instance method with a matching argument list
    # e.g. react(channelName, username, index, reaction)
    COMMANDS = {
      GRUEDUMP: [],
      GIBBERDUMP: [],
      MSG: %i[CHANNEL TEXT],
      DELETE: %i[CHANNEL INTEGER],
      REACT: %i[CHANNEL WORD INTEGER WORD],
      GIBBER_PERIOD: %i[INTEGER],
      GIBBER_METHOD: %i[WORD],
    }.freeze

    # @param harmless The plugin instance
    # @param bot The discordrb bot instance
    def initialize(harmless, bot)
      @harmless = harmless
      @bot = bot
      raise "Remote control password not set" unless Credentials::COMMAND_PHRASE
    end

    # Received message callback
    def process_message(message)
      text = message.content.strip
      return false unless text.start_with?(Credentials::COMMAND_PHRASE)

      begin
        run_command(text.sub(/^#{Credentials::COMMAND_PHRASE}\s*/o, "")) do |response|
          message.send_message(response) if response
        end
      rescue
        # Ensure that we don't propagate the command phrase to other plugins even if something goes wrong
      end
      true
    end

    # Command methods
    # Dump the grueing database
    def gruedump
      @harmless.gruedump
      "Dumped grue database"
    end

    def gibberdump
      @harmless.gibberdump
      "Dumped gibber database"
    end

    # Send a message to a channel
    # @param channel_name A channel identifier
    # @param text The message to send
    def msg(channel_name, text)
      @bot.send_message(@harmless.lookup_channel(channel_name).id, text)
      nil
    end

    # Delete one of this user's messages from a channel
    # @param channel_name A channel identifier
    # @param my_message_index The (0-based) index (from most recent backward) of the message to be deleted
    # @note To delete the second-to-last message from #banana, call delete('#banana', 1)
    # @return A status message
    def delete(channel_name, my_message_index)
      RemoteControl.validate_message_index(my_message_index)
      channel = @harmless.lookup_channel(channel_name)
      validator = proc { |message| message.author.id == @bot.profile.id }
      @harmless.lookup_message(channel, my_message_index, validator) do |message|
        channel.delete_message(message.id)
        return "Deleted: #{message.content} from ##{channel.name} on #{channel.server.name}"
      end
    end

    # React to a message
    # @param channel_name The channel identifier for the message to react to
    # @param user The display name of the user who posted the message
    # @param message_index The (0-based) index (from most recent backward) of the user's message to be reacted to
    # @param reaction The reaction text
    # @note Server-specific reactions don't work yet
    def react(channel_name, user, message_index, reaction)
      RemoteControl.validate_message_index(message_index)
      channel = @harmless.lookup_channel(channel_name)
      validator = proc { |message| message.author.display_name == user }
      @harmless.lookup_message(channel, message_index, validator) do |message|
        message.react(reaction)
      end
      nil
    end

    def gibber_period(period)
      @harmless.gibber_period(period)
      "Gibber response period set to #{period}"
    end

    def gibber_method(method)
      case method&.downcase
      when "raw"
        @harmless.gibber_use_nlp(false)
      when "nlp"
        @harmless.gibber_use_nlp(true)
      else
        raise "Invalid gibber method '#{method}'"
      end
    end

    def self.validate_message_index(message_index)
      raise "Invalid message index #{message_index}" if message_index.negative? || message_index > Harmless::MESSAGE_LOOKUP_COUNT
    end

    # Parse a command from a string
    # @param command_string A remote control command string
    # @return [:command, [arguments]] or nil
    # @see COMMANDS
    def self.parse_command(command_string)
      command, argument_string = Parsel::Parsel.parse_word(command_string)
      parameters = COMMANDS[command.to_sym]
      arguments = Parsel::Parsel.parse_arguments(parameters, argument_string)
      arguments ? [command.downcase.to_sym, arguments] : nil
    rescue => error
      puts "Command error parsing '#{command} #{argument_string}': #{error}"
      nil
    end

    # Execute a command string
    # @param command A command string, e.g. 'MSG #sslug whatever'
    def run_command(command)
      command, arguments = RemoteControl.parse_command(command)
      return nil unless command && arguments

      yield method(command).call(*arguments)
    end
  end
end
