# frozen_string_literal: true
require_relative 'command'

module Redis
  class Handshake
    def initialize(client, listening_port)
      @client = client
      @listening_port = listening_port
    end

    def call
      client.send_command ping
      client.send_command repl_conf('listening-port', listening_port)
      client.send_command repl_conf('capa', 'psync2')
      client.send_command psync
    end

    private
    attr_reader :client, :listening_port

    def ping
      command = Command.new
      command.type = 'PING'
      command
    end

    def repl_conf(key, value)
      command = Command.new
      command.type = 'REPLCONF'
      command.key = key
      command.value = value
      command
    end

    def psync
      command = Command.new
      command.type = 'PSYNC'
      command
    end
  end
end
