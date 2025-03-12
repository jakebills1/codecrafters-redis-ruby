require "minitest/autorun"
require_relative '../../lib/redis/command'

describe ::Redis::Command do
  before do
    @command = ::Redis::Command.new
  end

  describe '#is_implemented?' do
    describe 'when passed a command type that is implemented' do
      it 'is true' do
        assert @command.is_implemented?('ECHO')
      end
    end
    describe 'when passed a command type that is not implemented' do
      it 'is false' do
        assert !@command.is_implemented?('INCR')
      end
    end
  end

  describe '#complete?' do
    describe '' do
      it 'is true' do
        @command.type = 'PING'
        @command.length = 1
        assert @command.complete?
      end
    end
    describe 'when the command does not has all necessary fields for its type filled out' do
      it 'is false' do
        @command.type = 'ECHO'
        @command.length = 2
        assert !@command.complete?
      end
    end
  end

  describe '#encoded_response' do
    describe 'when the type should respond with a simple string encoding' do
      it 'returns a simple string encoding' do
        @command.type = 'PING'
        assert @command.encoded_response.start_with? '+'
      end
    end
    describe 'when the type should respond with a bulk string encoding' do
      it 'returns a bulk string encoding' do
        @command.type = 'ECHO'
        @command.value = 'hey'
        assert @command.encoded_response.start_with? '$'
      end
    end
  end
end
