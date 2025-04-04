# frozen_string_literal: true
module Redis
  module Commands
    class Info < Base
      def type
        'INFO'
      end

      def encoded_response(config)
        # hardcoded for now
        info = []
        {
          role: config.replicaof ? 'slave' : 'master',
          master_replid: '8371b4fb1155b71f4a04d3e1bc3e18c4a990aeeb',
          master_repl_offset: 0
        }.each do |k, v|
          info << [k.to_s, v.to_s].join(':')
        end
        as_bulk_string info.join("\n")
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
