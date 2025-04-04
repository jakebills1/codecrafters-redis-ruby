# frozen_string_literal: true
require_relative 'logger'
require 'optparse'

options = {}

module Redis
  class Configuration
    DEFAULT_PORT = 6379
    include Logger

    attr_reader :port, :dir, :dbfilename, :replicaof, :leader_host, :leader_port
    def initialize(cl_args)
      @cl_args = cl_args
    end

    def configure!
      OptionParser.new do |parser|
        parser.on("--dir DIR") do |dir|
          @dir = dir
        end
        parser.on("--dbfilename DBNAME") do |dbfilename|
          @dbfilename = dbfilename
        end
        parser.on("--port PORT") do |port|
          @port = port.to_i
        end
        parser.on("--replicaof LEADER") do |leader|
          host, port = leader.split(' ')
          @replicaof = leader
          @leader_host = host
          @leader_port = port
        end
      end.parse(cl_args)
      @port ||= DEFAULT_PORT
      log "configured redis server. port = #{port}, dir = #{dir}, dbfilename = #{dbfilename}"
      self
    rescue OptionParser::InvalidOption
      raise ConfigurationError
    end

    private
    attr_reader :cl_args
  end
  class ConfigurationError < StandardError; end
end
