require "socket"
require "nio4r"
require_relative './logger'
require_relative './command'
require_relative './protocol_io'
require_relative './command_state'

module Redis
  class Server
    include Logger
    include ProtocolIO

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
      monitor.value = proc { read_command(monitor, Command.new, CommandState.new) }
    end

    def read_command(monitor, command, state)
      # 1. read in 4 bytes, first 2 should be array length m + \r\n
      # 2. m times:
      #   1. read 4 bytes, this is the string length indicator n + \r\n
      #   2. read n + 2 bytes and strip off \r\n
      #   3. pass those bytes into parser
      # 3. once command has read m bulk strings, it is complete
      until state.complete?
        log state.current
        case state.current
        when :read_length
          command.length = read_token(monitor.io).delete("*").to_i
        when :read_type
          command.type = read_bulk_string(monitor.io)
        when :read_key
          command.key = read_bulk_string(monitor.io)
        when :read_value
          command.value = read_bulk_string(monitor.io)
        when :read_option_key
          command.pending_option_key = read_bulk_string(monitor.io)
        when :read_option_value
          opt_value = read_bulk_string(monitor.io)
          command.set_option(command.pending_option_key, opt_value)
        end
        state.transition! command
      end
      command.persist!
      monitor.interests = :w
      monitor.value = proc { respond(monitor, command) }
    rescue IO::WaitReadable
      monitor.value = proc { read_command(monitor, command, state) }
    rescue EOFError
      selector.deregister(monitor)
    end

    def respond(monitor, command)
      # log "write callback"
      monitor.io.write_nonblock(command.encoded_response)
      monitor.interests = :r
      monitor.value = proc { read_command(monitor, Command.new, CommandState.new) }
    rescue IO::WaitWritable
    end

    def cleanup
      server.close
      selector.close
      # log 'redis shutting down gracefully'
      exit
    end
  end
end
