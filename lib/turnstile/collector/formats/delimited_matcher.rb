module Turnstile
  module Collector
    module Formats
      module DelimitedMatcher
        class << self
          attr_accessor :marker
        end

        self.marker = 'x-turnstile'.freeze

        # Expects the form of '..... x-turnstile|desktop|10.10.2.4|1234456   ....'
        def delimited_matcher(delimiter = '|', match_marker = ::Turnstile::Collector::Formats::DelimitedMatcher.marker)
          @default_matcher ||= RegexpMatcher.new(%r{#{match_marker}},
                                                 ->(line) {
                                             marker = line.split(/ /).find { |w| w =~ /^#{match_marker}/ }
                                             if marker
                                               list = marker.split(delimiter)
                                               if list && list.size == 4
                                                 return(list[1..-1].join(':'))
                                               end
                                             end
                                             nil
                                           })
        end
      end

    end
  end
end

