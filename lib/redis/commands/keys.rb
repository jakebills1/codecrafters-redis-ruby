# frozen_string_literal: true
module Redis
  module Commands
    class Keys < Base
      def type
        'KEYS'
      end

      def encoded_response(config)
        matching_entries = scan(key)
        as_bulk_array(*matching_entries)
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
