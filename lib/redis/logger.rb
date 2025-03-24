require 'logger'
module Redis
  module Logger
    def log(msg)
      # return unless ENV['RS_DEBUG']

      logger.add(::Logger::INFO, msg)
    end

    def logger
      @logger ||= ::Logger.new($stdout)
    end
  end
end
