# frozen_string_literal: true
require_relative './entry'

module Storage
  DB ||= {}
  def get(key)
    entry = DB[key]
    if entry && entry.options[:px]
      return entry.value unless entry.expired?

      set(key, nil)
    elsif entry
      return entry.value
    end
    nil
  end

  def set(key, value, options = {})
    DB[key] = ::Redis::Entry.new(value, options)
  end
end
