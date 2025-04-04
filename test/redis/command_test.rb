require "minitest/autorun"

require_relative '../../lib/redis/base'
require_relative '../../lib/redis/configuration'

describe ::Redis::Base do
  before do
    @command = ::Redis::Base.new
    @config = ::Redis::Configuration.new(['--dir', 'tmp']).configure!
  end

  describe '#is_implemented?' do
    describe 'when passed a command type that is implemented' do
      it 'is true' do
        assert @command.is_implemented?('ECHO')
      end
    end
    describe 'when passed a command type that is not implemented' do
      it 'is false' do
        assert !@command.is_implemented?('FOO')
      end
    end
  end

  describe '#is_implemented_option?' do
    describe 'when passed an option that is implemented' do
      it 'is true' do
        assert @command.is_implemented_option?('px')
      end
    end
    describe 'when passed an option that is not implemented' do
      it 'is false' do
        assert !@command.is_implemented_option?('ex')
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
          @command.length = 4
          @command.type = 'SET'
          @command.key = 'foo'
          @command.value = 'bar'
          @command.set_option(:px, 100 )
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
        get_command = ::Redis::Base.new
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
        get_command = ::Redis::Base.new
        sleep 1
        get_command.type = 'GET'
        get_command.key = 'foo'
        assert get_command.encoded_response(@config) == "$3\r\nbar\r\n"
      end
    end
    describe 'when the type should respond with a bulk array encoding for CONFIG' do
      it 'returns a bulk array encoding' do
        @command.type = 'CONFIG'
        @command.key = 'GET'
        assert @command.encoded_response(@config).start_with? '*2'
      end
    end
    describe 'when the type should respond with a bulk array encoding for KEYS' do
      it 'returns a bulk array encoding' do
        @command.type = 'KEYS'
        @command.key = '*'
        assert @command.encoded_response(@config).start_with? '*'
      end
    end
    describe 'when the type should respond with a bulk string encoding for INFO' do
      it 'returns a bulk string encoding' do
        @command.type = 'INFO'
        assert @command.encoded_response(@config).start_with? '$'
      end
    end
  end

  describe '#value_required?' do
    describe 'for command types that do not require values' do
      it 'returns false' do
        ['PING', 'GET', 'KEYS', 'INFO', 'CONFIG'].each do |type|
          @command.type = type
          assert !@command.value_required?
          assert @command.value_not_required?
        end
      end
    end
    describe 'for command types that require values' do
      it 'returns true' do
        ['SET', 'ECHO'].each do |type|
          @command.type = type
          assert @command.value_required?
          assert !@command.value_not_required?
        end
      end
    end
  end

  describe '#key_required?' do 
    describe 'for command types that do not require keys' do
      it 'returns false' do
        ['PING', 'ECHO'].each do |type|
          @command.type = type
          assert !@command.key_required?
          assert @command.key_not_required?
        end
      end
    end
    describe 'for command types that require keys' do
      it 'returns true' do
        ['SET', 'GET', 'KEYS', 'CONFIG'].each do |type|
          @command.type = type
          assert @command.key_required?
          assert !@command.key_not_required?
        end
      end
    end
  end

end
