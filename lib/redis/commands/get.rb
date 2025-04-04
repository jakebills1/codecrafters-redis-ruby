# frozen_string_literal: true
module Redis
  module Commands
    class Get < Base
      def type
        'GET'
      end

      def encoded_response(config)
        retrieved_value = get(key)
        retrieved_value ? as_bulk_string(retrieved_value) : null_string
      end

      def key_required?
        true
      end

      def value_required?
        false
      end
    end
  end
end
