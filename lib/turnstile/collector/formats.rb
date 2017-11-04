require 'json'
require_relative 'matcher'

module Turnstile
  module Collector
    module Formats
      MARKER_TURNSTILE = 'x-turnstile'.freeze

      # Extracts from the log file of the form:
      # {"method":"GET","path":"/api/v1/saves/4SB8U-1Am9u-4ixC5","format":"json","duration":49.01,.....}
      def json_matcher(*_args)
        @json_matcher ||= Matcher.new(%r{"ip_address":"\d+},
                                      ->(line) {
                                        begin
                                          data = JSON.parse(line)
                                          [
                                            data['platform'],
                                            data['ip_address'],
                                            data['user_id']
                                          ].join(':')
                                        rescue
                                          nil
                                        end
                                      })
      end

      # Expects the form of '..... x-turnstile|desktop|10.10.2.4|1234456   ....'
      def delimited_matcher(delimiter = '|')
        @default_matcher ||= Matcher.new(%r{#{MARKER_TURNSTILE}},
                                         ->(line) {
                                           marker = line.split(/ /).find { |w| w =~ /^#{MARKER_TURNSTILE}/ }
                                           if marker
                                             list = marker.split(delimiter)
                                             if list && list.size == 4
                                               return(list[1..-1].join(':'))
                                             end
                                           end
                                           nil
                                         })
      end

      alias default_matcher delimited_matcher
    end
  end
end

