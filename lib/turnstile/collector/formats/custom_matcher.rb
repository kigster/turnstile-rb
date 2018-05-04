module Turnstile
  module Collector
    module Formats
      module CustomMatcher

        # Returns a custom matcher that is expected to be pre-initialized
        # using a config file.
        #
        # Example of a custom matcher configuration is in the README, and inside
        # the `example` folder.
        #
        def custom_matcher
          @custom_matcher ||= Turnstile.config.custom_matcher
        end
      end
    end
  end
end

