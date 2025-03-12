# frozen_string_literal: true

module Storage
  DB = {}
  def get(key)
    DB[key]
  end

  def set(key, value)
    DB[key] = value
  end
end
