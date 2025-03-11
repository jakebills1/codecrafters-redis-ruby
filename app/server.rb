require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    puts("Logs from your program will appear here!")

    # Uncomment this block to pass the first stage
    server = TCPServer.new(@port)
    loop do
      client = server.accept
      pid = fork do
        server.close
        @client = client
        while @client.read(14)
          @client.write("+PONG\r\n")
        end
        @client.close
      end
      Process.detach(pid)
    end
    server.close
  end
end

YourRedisServer.new(6379).start
