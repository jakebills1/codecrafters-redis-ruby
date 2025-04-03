# frozen_string_literal: true

module Redis
  class Entry
    attr_accessor :expires_at
    attr_reader :value, :timestamp
    def initialize(value)
      @value = value
      @timestamp = current_time_ms
    end

    def set_expiry(expires_in)
      return unless expires_in

      @expires_at = expires_in.to_i + timestamp
    end

    def expired?
      return false unless expires_at
      
      current_time_ms > expires_at
    end

    private
    def current_time_ms
      t = Time.now
      just_ms = t.nsec / 1_000_000
      seconds_in_ms = t.to_i * 1000
      seconds_in_ms + just_ms
    end
  end
end
