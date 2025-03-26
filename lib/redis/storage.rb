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

  def scan(search_term)
    # only supported arg for keys right now
    if search_term == '*'
      DB.keys
    else
      []
    end
  end
end
