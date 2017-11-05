require 'hashie/mash'
require 'hashie/extensions/mash/symbolize_keys'
require_relative 'redis/adapter'

require_relative 'dependencies'

module Turnstile
  class Stats < ::Hashie::Mash
    include ::Hashie::Extensions::Mash::SymbolizeKeys
  end

  class Observer
    include Dependencies

    def stats
      data      = adapter.fetch
      platforms = Hash[data.group_by { |d| d[:platform] }.map { |k, v| [k, sampler.extrapolate(v.count)] }]
      total     = platforms.values.inject(:+) || 0
      Stats.new({
                  stats: {
                    total:     total,
                    platforms: platforms
                  },
                  users: data
                })
    end

  end
end
