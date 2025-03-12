# frozen_string_literal: true
require_relative '../lib/redis_protocol_parser'

echo = ['*2', '$4', 'ECHO', '$3', 'hey']
ping = ['*1', '$4', 'PING']

parser = RedisProtocolParser.new

puts parser.command_complete? ? "newly instantiated parser has complete command" : "newly instantiated parser does not have complete command"
until parser.command_complete?
  parser.parse echo.shift
end

puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response

parser = RedisProtocolParser.new

until parser.command_complete?
  parser.parse ping.shift
end

puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response
