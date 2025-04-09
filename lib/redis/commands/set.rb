# frozen_string_literal: true
module Redis
  module Commands
    class Set < Base
      def type
        'SET'
      end

      def encode_self
        as_bulk_array type, key, value
      end

      def encoded_response(config)
        as_simple_string 'OK'
      end

      def key_required?
        true
      end

      def value_required?
        true
      end

      def perform_side_effects!(conn, config)
        set(key, value, options)
      end

      def write?
        true
      end
    end
  end
end
