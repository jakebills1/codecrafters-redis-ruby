require "socket"
require "nio4r"
require_relative 'logger'
require_relative 'reader'
require_relative 'command_builder'
require_relative 'bad_read_error'
require_relative 'storage'
require_relative 'rdb_parser'
require_relative 'handshake'
require_relative 'client'

module Redis
  class Server
    include Logger

    def initialize(config)
      @config = config
      @port = config.port
      @server = TCPServer.new(@port)
      @selector = NIO::Selector.new
      if config.dir && config.dbfilename
        load_data
      end
      if config.replicaof
        Handshake.new(
          Client.new(config.leader_host, config.leader_port),
          config.port.to_s
        ).call
      end
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
    attr_reader :server, :port, :selector, :config

    def load_data
      rdb_file_path = [config.dir, config.dbfilename].join('/')
      begin
        parser = RDBParser.new rdb_file_path
        parser.parse
        # only need to support single database right now
        Storage.const_set 'DB', parser.data[0]
        log parser.data
        log Storage.const_get 'DB'
      rescue Errno::ENOENT => e
        # the codecrafters tester might give a nonexisting file path
        # might not want to ignore this error irl
        log "error loading rdb file at #{rdb_file_path}: #{e}"
      rescue NotAnRDBFile => e
        log e
        cleanup
      end
    end


    def accept_new_client
      client = server.accept
      log "accepted new client"
      monitor = selector.register(client, :r)
      monitor.value = proc { read_command(monitor, CommandBuilder.new(Reader.new(monitor.io), monitor.io, config)) }
    end

    def read_command(monitor, command_builder)
      # 1. read in 4 bytes, first 2 should be array length m + \r\n
      # 2. m times:
      #   1. read 4 bytes, this is the string length indicator n + \r\n
      #   2. read n + 2 bytes and strip off \r\n
      #   3. pass those bytes into parser
      # 3. once command has read m bulk strings, it is complete
      #
      # todo: bytes written need to be added to the offset
      command = command_builder.build
      if command.write? && !config.replicaof
        config.replicas.each do |replica|
          Thread.new do
            replica.write command.encode_self
          end
        end
      end
      monitor.interests = :w
      monitor.value = proc { respond(monitor, command) }
    rescue IO::WaitReadable, BadReadError => e
      # reads can fail, in which case we want to retry this method
      # with the configured command and state
      # when the IO is selected for reading again
      log "error caught: '#{e}' at #{e.backtrace}"
      log command_builder.debug
      monitor.value = proc { read_command(monitor, command_builder) }
    rescue EOFError
      selector.deregister(monitor)
    end

    def respond(monitor, command)
      log "writing response to command #{command.type}: #{command.encoded_response(config)}"
      monitor.io.write_nonblock(command.encoded_response(config))
      monitor.interests = :r
      monitor.value = proc { read_command(monitor, CommandBuilder.new(Reader.new(monitor.io), monitor.io, config)) }
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
