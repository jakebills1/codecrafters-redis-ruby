require_relative './encoder'
require_relative './storage'
require_relative './logger'

module Redis
  class CommandTypeNotImplementedError < StandardError; end
  class Command
    include Encoder
    include Storage
    include Logger

    IMPLEMENTED_TYPES = ['PING', 'ECHO', 'SET', 'GET', 'CONFIG', 'KEYS', 'INFO', 'REPLCONF', 'PSYNC'].freeze
    IMPLEMENTED_OPTIONS = ['px']
    attr_accessor :length, :type, :key, :value, :options, :pending_option_key, :subtype

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

    def set_option(option_key, value)
      options[option_key.to_sym] = value
      @pending_option_key = nil
    end

    def value_not_required?
      !value_required?
    end

    def value_required?
      false
    end

    def key_required?
      false
    end

    def subtype_required?
      false
    end

    def key_not_required?
      !key_required?
    end

    def count_of_attrs
      count = 0
      count += 1 if type
      count += 1 if value
      count += 1 if key
      count + options.keys.size
    end

    def persist!
      # will be overridden in SET
    end

    def remaining_option_count
      (length - count_of_attrs) / 2
    end

    def inspect
      "self = #{self}, length = #{length}, type = #{type}, subtype = #{subtype}, key = #{key}, value = #{value}, pending_option_key = #{pending_option_key}, options = #{options}"
    end

    def type=(type_value)
      if is_implemented?(type_value)
        @type = type_value
      else
        raise CommandTypeNotImplementedError, "#{type_value} not an implemented command"
      end
    end

    def encoded_response(config)

    end
  end
end
