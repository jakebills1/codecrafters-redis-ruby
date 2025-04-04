require_relative 'command_state'
require_relative 'logger'
require_relative 'bad_read_error'
require_relative 'commands/base'
require_relative 'commands/not_implemented'
require_relative 'commands/ping'
require_relative 'commands/echo'
require_relative 'commands/set'
require_relative 'commands/get'
require_relative 'commands/config'
require_relative 'commands/keys'
require_relative 'commands/info'
require_relative 'commands/replconf'
require_relative 'commands/psync'

module Redis
  class CommandBuilder
    include Logger
    def initialize(reader)
      @reader = reader
      @command = Commands::Base.new # starts abstract, get specific klass from type
      @state = CommandState.new
    end

    def build
      until state.complete?
        case state.current
        when :read_length
          command_length = reader.read_token.delete("*").to_i
          if command_length < 1
            raise BadReadError
          end
          command.length = command_length
        when :read_type
          type = reader.read_bulk_string
          length = command.length
          @command = command_klass(type).new
          command.length = length
          command.type = type
        when :read_subtype
          command.subtype = reader.read_bulk_string
        when :read_key
          command.key = reader.read_bulk_string
        when :read_value
          command.value = reader.read_bulk_string
        when :read_option_key
          command.pending_option_key = reader.read_bulk_string
        when :read_option_value
          opt_value = reader.read_bulk_string
          command.set_option(command.pending_option_key, opt_value)
        end
        debug
        state.transition! command
      end

      command.persist!
      command
    end

    def debug
      log "state = #{state.current}"
      log command.inspect
    end

    private
    attr_reader :reader, :command, :state

    def command_klass(type)
      case type
      when 'PING'
        Commands::Ping
      when 'ECHO'
        Commands::Echo
      when 'SET'
        Commands::Set
      when 'GET'
        Commands::Get
      when 'CONFIG'
        Commands::Config
      when 'KEYS'
        Commands::Keys
      when 'INFO'
        Commands::Info
      when 'REPLCONF'
        Commands::Replconf
      when 'PSYNC'
        Commands::Psync
      else
        raise Commands::NotImplemented
      end
    end
  end
end
