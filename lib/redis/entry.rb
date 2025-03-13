# frozen_string_literal: true

module Redis
  class Entry
    attr_reader :value, :options
    def initialize(value, options)
      @value = value
      @options = options
      @timestamp = current_time_ms
    end

    def expired?
      false unless options[:px]
      (current_time_ms - timestamp) > options[:px].to_i
    end

    private
    attr_reader :timestamp
    def current_time_ms
      t = Time.now
      just_ms = t.nsec / 1_000_000
      seconds_in_ms = t.to_i * 1000
      seconds_in_ms + just_ms
    end
  end
end
