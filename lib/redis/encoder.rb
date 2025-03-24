
module Redis
  module Encoder
    def as_bulk_string(message)
      "$#{message.length}\r\n#{message}\r\n"
    end

    def as_simple_string(message)
      "+#{message}\r\n"
    end

    def null_string
      "$-1\r\n"
    end

    def as_bulk_array(*messages)
      encoded_ary = "*#{messages.size}\r\n"
      messages.each { |msg| encoded_ary << as_bulk_string(msg) }
      encoded_ary
    end
  end
end