# frozen_string_literal: true

module Redis
  class Echo < Base
    def type
      'ECHO'
    end

    def encoded_response(config)
      as_simple_string value
    end

    def value_required?
      true
    end

    def key_required?
      false
    end
  end
end
