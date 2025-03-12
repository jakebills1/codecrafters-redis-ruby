# frozen_string_literal: true

module Redis
  module Encoder
    def as_bulk_string(message)
      "$#{message.length}\r\n#{message}\r\n"
    end

    def as_simple_string(message)
      "+#{message}\r\n"
    end
  end
end