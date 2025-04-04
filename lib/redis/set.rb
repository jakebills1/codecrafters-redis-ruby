# frozen_string_literal: true

module Redis
  class Set < Command
    def type
      'SET'
    end

    def encoded_response(config)
      as_simple_string 'OK'
    end

    def key_required?
      true
    end

    def value_required?
      true
    end

    def persist!
      set(key, value, options)
    end
  end
end
