$LOAD_PATH.unshift File.expand_path(".", "lib")
require 'redis/server'
require 'redis/configuration'

configuration = ::Redis::Configuration.new(ARGV).configure!
::Redis::Server.new(configuration).start
