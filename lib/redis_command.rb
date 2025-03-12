# frozen_string_literal: true
require_relative './encoder'

class RedisCommand
  include Encoder
  IMPLEMENTED_TYPES = ['PING', 'ECHO'].freeze
  attr_accessor :length, :type, :value, :options

  def initialize
    @options = {}
  end

  def is_implemented?(type)
    IMPLEMENTED_TYPES.include? type
  end

  def complete?
    length && type && (value || type == "PING")
  end

  def encoded_response
    case type
    when 'PING'
      as_simple_string('PONG')
    when 'ECHO'
      as_bulk_string(value)
    end
  end
end
