# frozen_string_literal: true
require_relative './command'

# called with a succession of tokens such as *2, $4, ECHO, hey
# uses those to configure it's RedisCommand instance
module Redis
  class ProtocolParser
    ARY_LENGTH_INDICATOR = "*".freeze
    STR_LENGTH_INDICATOR = "$".freeze


    def initialize
      @command = Command.new
    end

    def parse(token)
      if token.start_with? ARY_LENGTH_INDICATOR
        command.length = token.delete(ARY_LENGTH_INDICATOR).to_i
      elsif command.is_implemented? token
        command.type = token
      elsif !token.start_with?(STR_LENGTH_INDICATOR)
        if ['SET', 'GET'].include?(command.type) && command.key.nil?
          command.key = token
        elsif command.value.nil?
          command.value = token
        else # option
          if command.is_implemented_option? token # key
            command.options[token] = 'pending'
          else # value
            # todo hacky, handle error if option not found
            option = command.options.find { |_, v| v == 'pending' }
            command.options[option.first] = token
          end
        end
      end
    end

    def command_complete?
      command.complete?
    end

    attr_reader :command
  end
end
