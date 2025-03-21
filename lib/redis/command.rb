# frozen_string_literal: true
require_relative './encoder'
require_relative './storage'
require_relative './logger'

module Redis
  class Command
    include Encoder
    include Storage
    include Logger

    IMPLEMENTED_TYPES = ['PING', 'ECHO', 'SET', 'GET'].freeze
    IMPLEMENTED_OPTIONS = ['px']
    attr_accessor :length, :type, :key, :value, :options, :pending_option_key

    def initialize
      @options = {}
    end

    def is_implemented?(type)
      IMPLEMENTED_TYPES.include? type
    end

    def is_implemented_option?(option)
      IMPLEMENTED_OPTIONS.include? option
    end

    def complete?
      length && (length == count_of_attrs)
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

    def set_option(option_key, value)
      options[option_key.to_sym] = value
      @pending_option_key = nil
    end

    def value_not_required?
      type == 'PING' || type == 'GET'
    end

    def value_required?
      !value_not_required?
    end

    def key_required?
      !key_not_required?
    end

    def key_not_required?
      !['SET', 'GET'].include? type
    end

    def count_of_attrs
      count = 0
      count += 1 if type
      count += 1 if value
      count += 1 if key
      count + options.keys.size
    end

    def persist!
      return unless type == 'SET'

      # puts key, value, options
      set(key, value, options)
    end

    def remaining_option_count
      (length - count_of_attrs) / 2
    end

    def inspect
      "self = #{self}, length = #{length}, type = #{type}, key = #{key}, value = #{value}, pending_option_key = #{pending_option_key}, options = #{options}"
    end
  end
end
