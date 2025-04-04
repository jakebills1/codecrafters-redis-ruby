# frozen_string_literal: true

module Redis
  class Config < Command
    def type
      'CONFIG'
    end
    def encoded_response(config)
      # hardcoding this to be for CONFIG GET dir for now
      as_bulk_array key, config.dir
    end

    def key_required?
      true
    end

    def value_required?
      subtype == 'SET'
    end

    def subtype_required?
      true
    end
  end
end
