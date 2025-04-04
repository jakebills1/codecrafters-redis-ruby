# frozen_string_literal: true
require_relative 'command'

module Redis
  class Ping < Command
    def type
      'PING'
    end

    def encoded_response(config)
      as_simple_string 'PONG'
    end

    def encode_self
      as_bulk_array type
    end

    def value_required?
      false
    end

    def key_required?
      false
    end
  end
end