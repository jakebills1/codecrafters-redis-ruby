require_relative './redis/server'
require_relative './redis/configuration'

configuration = ::Redis::Configuration.new(6379, ARGV).configure!
::Redis::Server.new(configuration).start
