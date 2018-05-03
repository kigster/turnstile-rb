require 'json'
require_relative 'regexp_matcher'
require_relative 'formats/json_matcher'
require_relative 'formats/delimited_matcher'
require_relative 'formats/custom_matcher'

module Turnstile
  module Collector
    module Formats

      include JsonMatcher
      include DelimitedMatcher
      include CustomMatcher

      alias default_matcher delimited_matcher
    end
  end
end

