require 'socket'
require_relative 'logger'

module Redis
  class Reader
    include Logger
    def initialize(io)
      @io = io
    end

    def read_bulk_string
      len = read_token.delete("$").to_i
      # + 2 bytes for the separator
      read_n_bytes(len + 2)
    end

    def read_token
      buf = ""
      io.read_nonblock(4, buf)
      if buf.length > 4
        raise 'short read'
      end
      log "read 4 bytes: #{buf}"
      buf.delete("\r\n")
    end

    def read_n_bytes(n_bytes)
      buf = ""
      io.read_nonblock(n_bytes, buf)
      log "read #{n_bytes} bytes: #{buf}"
      buf.delete("\r\n")
    end

    private
    attr_reader :io
  end
end

