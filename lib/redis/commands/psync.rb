# frozen_string_literal: true

module Redis
  module Commands
    class Psync < Base
      def type
        'PSYNC'
      end

      def encode_self
        as_bulk_array type, '?', '-1'
      end

      def encoded_response(config)
        as_simple_string "FULLRESYNC #{config.master_replid} #{config.master_repl_offset}"
      end

      def key_required?
        false
      end

      def value_required?
        false
      end
    end
  end
end
