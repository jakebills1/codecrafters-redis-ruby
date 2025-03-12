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
      describe 'and the command type does not require a key attr to be set' do
        it 'sets the commands value attr' do
          @parser.parse 'hey'
          assert @parser.command.value == 'hey'
        end
      end
    end
  end
  describe '#command_complete?' do
    describe 'the command type is ECHO' do
      it 'reports the command is complete' do
        ['*2', '$4', 'ECHO', '$3', 'hey'].each do |token|
          @parser.parse token
        end
        assert @parser.command_complete?
      end
      it 'reports the command is incomplete' do
        ['*2', '$4', 'ECHO', '$3'].each do |token|
          @parser.parse token
        end
        assert !@parser.command_complete?
      end
    end
    describe 'the command type is SET' do
      describe 'and all required attrs are parsed' do
        it 'reports the command is complete' do
          ['*3', '$3', 'SET', '$3', 'foo', '$3', 'bar'].each do |token|
            @parser.parse token
          end
          assert @parser.command_complete?
        end
      end
      describe 'and not all required attrs are parsed' do
        it 'reports the command is incomplete' do
          ['*3', '$3', 'SET', '$3', 'foo'].each do |token|
            @parser.parse token
          end
          assert !@parser.command_complete?
        end
      end
    end
    describe 'the command type is GET' do
      describe 'and all required attrs are parsed' do
        it 'reports the command is complete' do
          ['*2', '$3', 'GET', '$3', 'foo'].each do |token|
            @parser.parse token
          end
          assert @parser.command_complete?
        end
      end
      describe 'and not all required attrs are parsed' do
        it 'reports the command is incomplete' do
          ['*2', '$3', 'GET'].each do |token|
            @parser.parse token
          end
          assert !@parser.command_complete?
        end
      end
    end
  end
end
