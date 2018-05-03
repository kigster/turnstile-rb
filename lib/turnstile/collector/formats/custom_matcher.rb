module Turnstile
  module Collector
    module Formats
      module CustomMatcher

        # Returns a custom matcher that is expected to be pre-initialized
        # using a config file.
        #
        # Example of a custom matcher configuration:
        #
        # # File: turnstile_config.rb
        #
        #        # This matcher extracts platform, UID and IP from the following CSV string:
        #        # 2018-05-02 21:51:44.031,25928,3997,th-M4wDQM4w0,web,j5v-dzg0J,69.181.72.240,e2b1be795372c385c92a7df420752992
        #        custom_matcher do |line|
        #           words = line.split(',')
        #           words[4..6]
        #        end
        #
        #
        def custom_matcher
          @custom_matcher ||= Turnstile.config.custom_matcher
        end
      end

    end
  end
end

