# frozen_string_literal: true
require 'socket'
require_relative 'logger'

module Redis
  class Client
    include Logger
    def initialize(host = 'localhost', port = 6379)
      @host = host
      @port = port
      @socket = TCPSocket.new host, port
    end

    def send_command(command)
      socket.puts command.encode_self
      log "Server said #{socket.gets}"
    end

    private
    attr_reader :host, :port, :socket
  end
end
