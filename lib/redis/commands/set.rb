# frozen_string_literal: true
module Redis
  module Commands
    class Set < Base
      def type
        'SET'
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

      def persist!
        set(key, value, options)
      end
    end
  end
end
