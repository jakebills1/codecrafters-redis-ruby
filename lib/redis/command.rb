# frozen_string_literal: true
require_relative './encoder'
require_relative './storage'

module Redis
  class Command
    include Encoder
    include Storage

    IMPLEMENTED_TYPES = ['PING', 'ECHO', 'SET', 'GET'].freeze
    attr_accessor :length, :type, :key, :value, :options

    def initialize
      @options = {}
    end

    def is_implemented?(type)
      IMPLEMENTED_TYPES.include? type
    end

    def complete?
      length && type && (value || value_not_required?) && (key || key_not_required?)
    end

    def encoded_response
      case type
      when 'PING'
        as_simple_string('PONG')
      when 'SET'
        as_simple_string('OK')
      when 'ECHO'
        as_bulk_string(value)
      when 'GET'
        retrieved_value = get(key)
        retrieved_value ? as_bulk_string(retrieved_value) : null_string
      end
    end

    def value=(incoming_value)
      if type == 'SET'
        set(key, incoming_value)
        @value = incoming_value
      else
        @value = incoming_value
      end
    end

    private
    def value_not_required?
      type == 'PING' || type == 'GET'
    end

    def key_not_required?
      !['SET', 'GET'].include? type
    end
  end
end
