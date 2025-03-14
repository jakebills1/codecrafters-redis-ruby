require 'socket'

module Redis
  module ProtocolIO
    def read_bulk_string(io)
      len = read_token(io).delete("$").to_i
      # + 2 bytes for the separator
      read_n_bytes(io, len + 2)
    end

    def read_token(io)
      buf = ""
      io.read_nonblock(4, buf)
      buf.delete("\r\n")
    end

    def read_n_bytes(io, n_bytes)
      buf = ""
      io.read_nonblock(n_bytes, buf)
      buf.delete("\r\n")
    end
  end
end