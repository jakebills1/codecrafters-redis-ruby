# frozen_string_literal: true
#
module Redis
  module Commands
    class Ping < Base
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
end