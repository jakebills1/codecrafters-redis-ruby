# frozen_string_literal: true
require 'socket'

module Redis
  class Client
    def initialize(host = 'localhost', port = 6379)
      @host = host
      @port = port
      @socket = TCPSocket.new host, port
    end

    def send_command(command)
      socket.puts command.encode_self
    end

    private
    attr_reader :host, :port, :socket
  end
end
