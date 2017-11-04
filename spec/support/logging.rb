module Turnstile
  module RSpec
    module Logging
      TEST_LOG = 'spec/log/test.log'

      def self.configure(file = TEST_LOG)
        return if Turnstile::Logger.enabled
        Turnstile::Logger.enable
        FileUtils.mkdir_p(File.dirname(file))

        Turnstile::Logger.logger       = ::Logger.new(file)
        Turnstile::Logger.logger.level = ::Logger::INFO
        Turnstile::Logger.logger
      end
    end
  end
end
