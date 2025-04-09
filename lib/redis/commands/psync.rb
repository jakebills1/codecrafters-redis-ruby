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
        # need to reply AND fork a process to send the rdb file to the replica
        as_simple_string "FULLRESYNC #{config.master_replid} #{config.master_repl_offset}"
      end

      def key_required?
        false
      end

      def value_required?
        false
      end

      def perform_side_effects!(conn, config)
        config.replicas << conn
        Thread.new do
          rdb_file_path = [config.dir, config.dbfilename].join('/')
          # hardcoding empty rdb file for now, but will use actual file in reality
          f = File.read 'empty.rdb'
          conn.write "$#{f.bytesize}\r\n"
          conn.write f
        end
      end
    end
  end
end
