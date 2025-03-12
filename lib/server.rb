require_relative './redis/server'

::Redis::Server.new(6379).start
