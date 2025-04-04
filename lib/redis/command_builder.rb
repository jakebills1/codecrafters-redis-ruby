require_relative 'command_state'
require_relative 'logger'
require_relative 'bad_read_error'

Dir[File.join(__dir__, 'commands', '*.rb')].each { |file| require_relative file }

module Redis
  class CommandBuilder
    include Logger
    def initialize(reader)
      @reader = reader
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
          @length = command_length
        when :read_type
          type = reader.read_bulk_string
          @command = Commands::Base.type_to_klass(type).new
          command.length = length
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
    attr_reader :reader, :command, :state, :length
  end
end
