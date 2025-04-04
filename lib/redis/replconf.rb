# frozen_string_literal: true

module Redis
  class Replconf < Base
    def type
      'REPLCONF'
    end

    def encoded_response(config)
      as_simple_string 'OK'
    end

    def encode_self
      as_bulk_array type, key, value
    end

    def key_required?
      true
    end

    def value_required?
      true
    end
  end
end
