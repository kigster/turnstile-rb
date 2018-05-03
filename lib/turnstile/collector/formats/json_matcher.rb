require 'json'
require_relative '../regexp_matcher'

module Turnstile
  module Collector
    module Formats
      # Extracts from the log file of the form:
      # {"method":"GET","path":"/api/v1/saves/4SB8U-1Am9u-4ixC5","format":"json","duration":49.01,.....}
      module JsonMatcher
        def json_matcher(*_args)
          @json_matcher ||= ::Turnstile::Collector::RegexpMatcher.new(%r{"ip_address":"\d+},
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
      end

    end
  end
end

