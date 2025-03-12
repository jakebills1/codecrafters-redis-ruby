# frozen_string_literal: true
require_relative './encoder'

module Redis
  class Command
    include Encoder
    IMPLEMENTED_TYPES = ['PING', 'ECHO', 'SET', 'GET'].freeze
    attr_accessor :length, :type, :value, :options

    def initialize
      @options = {}
    end

    def is_implemented?(type)
      IMPLEMENTED_TYPES.include? type
    end

    def complete?
      length && type && (value || value_not_required?)
    end

    def encoded_response
      case type
      when 'PING'
        as_simple_string('PONG')
      when 'SET'
        as_simple_string('OK')
      when 'ECHO', 'GET'
        as_bulk_string(value)
      end
    end

    def value=(incoming_value)
      if type == 'SET'
        # persist value
      elsif type == 'GET'
        # fetch from storage
      else
        @value = incoming_value
      end
    end

    private
    def value_not_required?
      type == 'PING' || type == 'SET'
    end
  end
end
