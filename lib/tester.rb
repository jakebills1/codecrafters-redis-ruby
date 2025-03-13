# frozen_string_literal: true
require_relative './redis/protocol_parser'

echo = ['*2', 'ECHO', 'hey']
ping = ['*1', 'PING']

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

parser = ::Redis::ProtocolParser.new
set_with_options = ['*5', 'SET', 'foo', 'bar', 'px', '100']
until set_with_options.empty?
  parser.parse set_with_options.shift
end

puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response, parser.command.options

set_with_multiple_options = ['*7', 'SET', 'foo', 'bar', 'px', '100', 'foo', 'baz']
parser = ::Redis::ProtocolParser.new
until set_with_multiple_options.empty?
  parser.parse set_with_multiple_options.shift
end
puts parser.command_complete? ? "parser is complete" : "parser is not complete"
puts parser.command.length, parser.command.type, parser.command.value, parser.command.encoded_response, parser.command.options

