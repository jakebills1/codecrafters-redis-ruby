# frozen_string_literal: true

module Redis
  class CommandState
    attr_reader :current
    def initialize
      @current = :read_length
    end

    def transition!(command)
      next_state = TRANSITIONS[current]
      if next_state.respond_to?(:call)
        @current = next_state.call(command)
      else
        @current = next_state
      end
    end

    def complete?
      current == :complete
    end

    private

    TRANSITIONS = {
      read_length: :read_type,
      read_type: proc do |command|
        if command.key_required?
          :read_key
        elsif command.value_required?
          :read_value
        elsif command.remaining_option_count > 0
          :read_option_key
        else
          :complete
        end
      end,
      read_key: proc do |command|
        if command.value_required?
          :read_value
        elsif command.remaining_option_count > 0
          :read_option_key
        else
          :complete
        end
      end,
      read_value: proc do |command|
        if command.remaining_option_count > 0
          :read_option_key
        else
          :complete
        end
      end,
      read_option_key: :read_option_value,
      read_option_value: proc do |command|
        if command.remaining_option_count > 0
          :read_option_key
        else
          :complete
        end
      end
    }.freeze
  end
end
