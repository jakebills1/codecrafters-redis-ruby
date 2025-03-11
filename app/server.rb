require "socket"
require "nio4r"
require_relative '../lib/logger'
class YourRedisServer
  include Logger

  PING_BYTES = 14
  PING_RESP = "+PONG\r\n"
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
      selector.select { |monitor| monitor.value.call }
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
    monitor.value = proc { read_from_client(monitor) }
  end

  def read_from_client(monitor)
    begin
      monitor.io.read_nonblock(PING_BYTES)
      monitor.interests = :w
      monitor.value = proc { write_to_client(monitor) }
    rescue IO::WaitReadable
    rescue EOFError
      selector.deregister(monitor)
      monitor.close
    end
  end

  def write_to_client(monitor)
    monitor.io.write_nonblock(PING_RESP)
    monitor.interests = :r
    monitor.value = proc { read_from_client(monitor) }
  rescue IO::WaitWritable
  end

  def cleanup
    server.close
    selector.close
    log 'redis shutting down gracefully'
    exit
  end
end

YourRedisServer.new(6379).start
