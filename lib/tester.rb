# frozen_string_literal: true
require_relative './redis/protocol_parser'

echo = ['*2', '$4', 'ECHO', '$3', 'hey']
ping = ['*1', '$4', 'PING']

parser = ::Redis::ProtocolParser.new

puts parser.command_complete? ? "newly instantiated parser has complete command" : "newly instantiated parser does not have complete command"
until parser.command_complete?
  parser.parse echo.shift
end

puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response

parser = ::Redis::ProtocolParser.new

until parser.command_complete?
  parser.parse ping.shift
end

puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response
