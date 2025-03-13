# frozen_string_literal: true

module Storage
  DB = {}
  def get(key)
    retrieved_value = DB[key]
    # puts retrieved_value
    if retrieved_value && retrieved_value.dig(:options, :px)
      expiry = retrieved_value.dig(:options, :px).to_i
      now = current_time_ms
      expired = (now - retrieved_value[:timestamp]) > expiry
      # puts "expiry = #{expiry}, now = #{now}, ts = #{retrieved_value[:timestamp]}, diff = #{now - retrieved_value[:timestamp]}"
      return retrieved_value[:value] unless expired

      set(key, nil)
    elsif retrieved_value
      return retrieved_value[:value]
    end
    nil
  end

  def set(key, value, options = {})
    inserting = { timestamp: current_time_ms, value:, options: }
    # puts "inserting #{inserting}"
    DB[key] = inserting
  end

  def current_time_ms
    t = Time.now
    just_ms = t.nsec / 1_000_000
    seconds_in_ms = t.to_i * 1000
    seconds_in_ms + just_ms
  end
end
