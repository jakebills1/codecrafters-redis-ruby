require "socket"
require "nio4r"
require_relative './protocol_parser'
require_relative './logger'

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
      monitor.value = proc { read_command(monitor, ProtocolParser.new) }
    end

    def read_command(monitor, parser)
      # log "started read callback"
      loop do
        # log "read callback loop started"
        begin
          token = readline_non_block(monitor.io)
          # log "read token from conn: #{token}"
          parser.parse(token)
          break if parser.command_complete?
        rescue IO::WaitReadable
          monitor.value = proc { read_command(monitor, parser) }
          return
        rescue EOFError
          selector.deregister(monitor)
          monitor.close
          return
        end
      end
      # log "read callback loop finished"
      # log "command type = #{parser.command.type}, command value = #{parser.command.value}"
      monitor.interests = :w
      monitor.value = proc { respond(monitor, parser.command) }
    end

    def respond(monitor, command)
      # log "write callback"
      monitor.io.write_nonblock(command.encoded_response)
      monitor.interests = :r
      monitor.value = proc { read_command(monitor, ProtocolParser.new) }
    rescue IO::WaitWritable
    end

    def cleanup
      server.close
      selector.close
      # log 'redis shutting down gracefully'
      exit
    end

    def readline_non_block(io)
      # this will raise an error if the read would block,
      # expecting that to be handled in read_command
      buf = ""
      while read_byte = io.read_nonblock(1)
        buf << read_byte
        if buf.end_with?("\r\n")
          return buf.sub("\r\n", "")
        end
      end
    end
  end
end
