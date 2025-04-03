require "minitest/autorun"

require_relative '../../lib/redis/command'
require_relative '../../lib/redis/configuration'

describe ::Redis::Command do
  before do
    @command = ::Redis::Command.new
    @config = ::Redis::Configuration.new([]).configure!
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
    describe 'when the command type is PING' do
      describe 'and has all necessary fields filled in' do
        it 'is true' do
          @command.type = 'PING'
          @command.length = 1
          assert @command.complete?
        end
      end
    end
    describe 'when the command type is SET' do
      describe 'and has all necessary fields filled in' do
        it 'is true' do
          @command.length = 3
          @command.type = 'SET'
          @command.key = 'foo'
          @command.value = 'bar'
          assert @command.complete?
        end
      end
      describe 'and does not have all necessary fields filled in' do
        it 'is false' do
          @command.length = 3
          @command.type = 'SET'
          @command.key = 'foo'
          assert !@command.complete?
        end
      end
    end
  end

  describe '#encoded_response' do
    describe 'when the type should respond with a simple string encoding' do
      it 'returns a simple string encoding' do
        @command.type = 'PING'
        assert @command.encoded_response(@config).start_with? '+'
      end
    end
    describe 'when the type should respond with a bulk string encoding' do
      it 'returns a bulk string encoding' do
        @command.type = 'ECHO'
        @command.value = 'hey'
        assert @command.encoded_response(@config).start_with? '$'
      end
    end
    describe 'when the type should respond with a null string encoding' do
      it 'returns a null string' do
        @command.type = 'GET'
        @command.value = 'foo'
        assert @command.encoded_response(@config).start_with? '$-1'
      end
    end
    describe 'when the entry has expired' do
      it 'returns a null string' do
        @command.type = 'SET'
        @command.key = 'foo'
        @command.value = 'bar'
        @command.set_option('px', '10')
        @command.persist!
        sleep 1
        get_command = ::Redis::Command.new
        get_command.type = 'GET'
        get_command.key = 'foo'
        assert get_command.encoded_response(@config).start_with? '$-1'
      end
    end
    describe 'when the entry has not expired' do
      it 'returns the value as bulk string' do
        @command.type = 'SET'
        @command.key = 'foo'
        @command.value = 'bar'
        @command.set_option('px', '10000')
        @command.persist!
        get_command = ::Redis::Command.new
        sleep 1
        get_command.type = 'GET'
        get_command.key = 'foo'
        assert get_command.encoded_response(@config) == "$3\r\nbar\r\n"
      end
    end
  end
end
