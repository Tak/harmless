# frozen_string_literal: true

require 'discordrb'
require_relative 'credentials'

module Harmless
  # Allow limited remote control of the bot
  class RemoteControl
    MESSAGE_LOOKUP_COUNT = 20

    # Each entry must correspond to an instance method with a matching argument list
    # e.g. react(channelName, username, index, reaction)
    COMMANDS = {
      GRUEDUMP: [],
      MSG: %i[CHANNEL TEXT],
      DELETE: %i[CHANNEL INTEGER],
      REACT: %i[CHANNEL WORD INTEGER WORD],
    }.freeze

    # @param harmless The plugin instance
    # @param bot The discordrb bot instance
    def initialize(harmless, bot)
      @harmless = harmless
      @bot = bot
      raise 'Remote control password not set' unless Credentials::COMMAND_PHRASE
    end

    # Received message callback
    def process_message(message)
      text = message.content.strip
      return unless text.start_with?(Credentials::COMMAND_PHRASE)

      run_command(text.sub(/^#{Credentials::COMMAND_PHRASE}\s*/, '')) do |response|
        message.send_message(response) if response
      end
    end

    # Command methods
    # Dump the grueing database
    def gruedump
      @harmless.gruedump
      'Dumped grue database'
    end

    # Send a message to a channel
    # @param channelName A channel identifier
    # @param text The message to send
    def msg(channelName, text)
      @bot.send_message(lookup_channel(channelName).id, text)
      nil
    end

    # Delete one of this user's messages from a channel
    # @param channelName A channel identifier
    # @param myMessageIndex The (0-based) index (from most recent backward) of the message to be deleted
    # @note To delete the second-to-last message from #banana, call delete('#banana', 1)
    # @return A status message
    def delete(channelName, myMessageIndex)
      RemoteControl.validate_message_index(myMessageIndex)
      channel = lookup_channel(channelName)
      validator = proc { |message| message.author.id == @bot.profile.id }
      lookup_message(channel, myMessageIndex, validator) do |message|
        channel.delete_message(message.id)
        return "Deleted: #{message.content} from ##{channel.name} on #{channel.server.name}"
      end
    end

    # React to a message
    # @param channelName The channel identifier for the message to react to
    # @param user The display name of the user who posted the message
    # @param messageIndex The (0-based) index (from most recent backward) of the user's message to be reacted to
    # @param reaction The reaction text
    # @note Server-specific reactions don't work yet
    def react(channelName, user, messageIndex, reaction)
      RemoteControl.validate_message_index(messageIndex)
      channel = lookup_channel(channelName)
      validator = proc { |message| message.author.display_name == user }
      lookup_message(channel, messageIndex, validator) do |message|
        message.react(reaction)
      end
      nil
    end

    def self.validate_message_index(messageIndex)
      raise "Invalid message index #{messageIndex}" if messageIndex.negative? || messageIndex > MESSAGE_LOOKUP_COUNT
    end

    # Tokenizer methods
    # Split the first whitespace-separated chunk from a string
    # @param argumentString
    # @return [token, remainderOfString]
    def self.parse_word(argumentString)
      argumentString.split(/\s+/, 2)
    end

    # Parse a channel name from the beginning of a string
    # @param argumentString A string beginning with a #channel identifier and whitespace
    # @return [#channelIdentifier, remainderOfString]
    # @raise When a valid channel identifier is not found
    def self.parse_channel(argumentString)
      channel, argumentString = parse_word(argumentString)
      raise "Invalid channel '#{channel}'" unless (match = channel.match((/^#([^\s]+)/)))

      [match[1], argumentString]
    end

    # Parse an integer from the beginning of a string
    # @param argumentString A string beginning with an integer
    # @return [parsedInteger, remainderOfString]
    # @raise ArgumentError When integer parsing fails
    def self.parse_integer(argumentString)
      integerString, argumentString = parse_word(argumentString)
      [Integer(integerString), argumentString]
    end

    # Parse all remaining text from a string
    # @param argumentString
    # @return [argumentString, nil]
    def self.parse_text(argumentString)
      raise 'End of input reached' unless argumentString

      [argumentString, nil]
    end

    # Get the appropriate method for parsing a parameter type
    # @param typeSymbol A type symbol, e.g. INTEGER
    # @return The parser method for the type symbol, e.g. parse_integer
    def self.get_parser_method_for(typeSymbol)
      method("parse_#{typeSymbol.to_s.downcase}".to_sym)
    end

    # Parse typed arguments from a string
    # @param parameterList A list of argument type parameters (i.e. COMMANDS)
    # @param argumentString The string to parse
    # @return Parsed token list or nil
    def self.parse_arguments(parameterList, argumentString)
      return nil unless parameterList

      tokens = parameterList.inject([]) do |tokens, parameter|
        token, argumentString = get_parser_method_for(parameter).call(argumentString)
        tokens << token
      end
      argumentString && !argumentString.strip.empty? ? nil : tokens
    end

    # Parse a command from a string
    # @param commandString A remote control command string
    # @return [:command, [arguments]] or nil
    # @see COMMANDS
    def self.parse_command(commandString)
      command, argumentString = parse_word(commandString)
      parameters = COMMANDS[command.to_sym]
      arguments = parse_arguments(parameters, argumentString)
      arguments ? [command.downcase.to_sym, arguments] : nil
    rescue => error
      puts "Command error parsing '#{command} #{argumentString}': #{error}"
      nil
    end

    # Execute a command string
    # @param command A command string, e.g. 'MSG #sslug whatever'
    def run_command(command)
      command, arguments = RemoteControl.parse_command(command)
      return nil unless command && arguments

      yield method(command).call(*arguments)
    end

    # Look up a channel
    # @param name The name of the desired channel
    # @return The first channel on connected servers matching name
    # @raise When no matching channel is found
    def lookup_channel(name)
      @bot.servers.each_value do |server|
        if (channel = server.text_channels.detect { |channel| channel.name == name })
          return channel
        end
      end
      raise "Failed to look up channel '##{name}'"
    end

    # Look up a message
    # @param channel The Channel instance to search for the message
    # @param messageIndex The (0-based) index of the message to be found
    # @param validator A predicate proc to be applied to messages to determine whether they should be considered
    # @yield The messageIndexth message matching validator
    def lookup_message(channel, messageIndex, validator)
      messageCount = 0
      channel.history(MESSAGE_LOOKUP_COUNT).each do |message|
        messageCount += 1 if validator.call(message)
        next unless messageCount > messageIndex

        yield message
        break
      end
    end
  end
end
