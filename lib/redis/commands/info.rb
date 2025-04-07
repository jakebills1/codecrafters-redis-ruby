# frozen_string_literal: true
module Redis
  module Commands
    class Info < Base
      def type
        'INFO'
      end

      def encoded_response(config)
        info = []
        {
          role: config.replicaof ? 'slave' : 'master',
          master_replid: config.master_replid,
          master_repl_offset: config.master_repl_offset
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
