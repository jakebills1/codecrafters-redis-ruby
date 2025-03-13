require "socket"
require "nio4r"
require_relative './logger'
require_relative './command'

module Redis
  class Server
    include Logger

    def initialize(port)
      @port = port
      @server = TCPServer.new(@port)
      @selector = NIO::Selector.new
      trap('INT') { cleanup }
    end

    def start
      monitor = selector.register(server, :r)
      monitor.value = proc { accept_new_client }
      loop do
        selector.select do |monitor|
          # log monitor
          monitor.value.call
        end
      end
    ensure
      server.close
      selector.close
    end

    private
    attr_reader :server, :port, :selector

    def accept_new_client
      client = server.accept
      monitor = selector.register(client, :r)
      monitor.value = proc { read_command(monitor, Command.new) }
    end

    def read_command(monitor, command)
      # 1. read in 4 bytes, first 2 should be array length m + \r\n
      # 2. m times:
      #   1. read 4 bytes, this is the string length indicator n + \r\n
      #   2. read n + 2 bytes and strip off \r\n
      #   3. pass those bytes into parser
      # 3. once command has read m bulk strings, it is complete
      begin
        command_length_token = read_token(monitor.io)
        command_length = command_length_token.delete("*").to_i
        command.length ||= command_length
        command.type ||= read_bulk_string(monitor.io)
        if command.key_required?
          command.key ||= read_bulk_string(monitor.io)
        end
        if command.value_required?
          command.value ||= read_bulk_string(monitor.io)
        end
        option_count = (command_length - command.count_of_attrs) / 2
        option_count.times do
          opt_key = read_bulk_string(monitor.io)
          opt_value = read_bulk_string(monitor.io)
          command.set_option(opt_key, opt_value)
        end
        command.persist!
      rescue IO::WaitReadable
        monitor.value = proc { read_command(monitor, command) }
        return
      rescue EOFError
        selector.deregister(monitor)
      end
      # log "read callback loop finished"
      # log "command type = #{parser.command.type}, command value = #{parser.command.value}"
      monitor.interests = :w
      monitor.value = proc { respond(monitor, command) }
    end

    def respond(monitor, command)
      # log "write callback"
      monitor.io.write_nonblock(command.encoded_response)
      monitor.interests = :r
      monitor.value = proc { read_command(monitor, Command.new) }
    rescue IO::WaitWritable
    end

    def cleanup
      server.close
      selector.close
      # log 'redis shutting down gracefully'
      exit
    end

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
