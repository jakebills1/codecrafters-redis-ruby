require_relative './redis/server'
require_relative './redis/configuration'

configuration = ::Redis::Configuration.new(ARGV).configure!
::Redis::Server.new(configuration).start
