# frozen_string_literal: true

module Redis
  class Configuration
    include Logger

    attr_reader :port, :dir, :dbfilename
    def initialize(port, cl_args)
      @port = port
      @cl_args = cl_args
    end

    def configure!
      cl_args.each_slice(2) do |key, value|
        case key
        when '--dir'
          @dir = value
        when '--dbfilename'
          @dbfilename = value
        else
          raise ConfigurationError, "unrecognized command line configuration. key = #{key}, value =  #{value}"
        end
      end
      log "configured redis server. port = #{port}, dir = #{dir}, dbfilename = #{dbfilename}"
      self
    end

    private
    attr_reader :cl_args
  end
  class ConfigurationError < StandardError; end
end
