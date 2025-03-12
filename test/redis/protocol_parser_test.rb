# frozen_string_literal: true
require "minitest/autorun"
require_relative '../../lib/redis/protocol_parser'

describe ::Redis::ProtocolParser do
  before do
    @parser = ::Redis::ProtocolParser.new
  end

  describe '#parse' do
    describe 'when passed an array length token' do
      it 'sets the commands length attr' do
        @parser.parse '*1'
        assert @parser.command.length == 1
      end
    end
    describe 'when passed an implemented command type' do
      it 'sets the commands type attr' do
        @parser.parse 'ECHO'
        assert @parser.command.type == 'ECHO'
      end
    end
    describe 'when passed a string that is not the string length indicator' do
      it 'sets the commands value attr' do
        @parser.parse 'hey'
        assert @parser.command.value == 'hey'
      end
    end
  end
  describe '#command_complete?' do
    describe 'when passed a series of valid redis command tokens' do
      it 'reports the command is complete' do
        ['*2', '$4', 'ECHO', '$3', 'hey'].each do |token|
          @parser.parse token
        end
        assert @parser.command_complete?
      end
    end
    describe 'when passed an incomplete series of redis command tokens' do
      it 'reports the command is incomplete' do
        ['*2', '$4', 'ECHO', '$3'].each do |token|
          @parser.parse token
        end
        assert !@parser.command_complete?
      end
    end
  end
end
