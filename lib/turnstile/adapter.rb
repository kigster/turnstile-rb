require 'redis'
require 'timeout'

require_relative 'logger/helper'

module Turnstile
  class Adapter
    SEP = ':'

    include Logger::Helper

    attr_accessor :redis
    include Timeout

    def initialize
      self.redis = config.redis.url ?
                     ::Redis.new(url: config.redis.url) :
                     ::Redis.new(host: config.redis.host,
                                 port: config.redis.port,
                                 db:   config.redis.db)
    end

    def add(uid, platform, ip)
      key = compose_key(uid, platform, ip)
      timeout(config.redis.timeout) do
        redis.setex(key, config.activity_interval, 1)
      end
    rescue StandardError => e
      error "exception while writing to redis: #{e.inspect}"
    end

    def fetch
      all_keys.map do |key|
        fields = key.split(SEP)
        {
          uid:      fields[1],
          platform: fields[2],
          ip:       fields[3],
        }
      end
    end

    def wipe
      keys = all_keys
      log_around('wiping the database, total keys: ') do
        redis.del(keys).to_s
      end
    end

    def all_keys
      redis.keys("#{prefix}*")
    end

    def aggregate
      all_keys.inject({}) { |hash, key| increment_platform(hash, key) }.tap do |h|
        h['total'] = h.values.inject(&:+) || 0
      end
    end

    def increment_platform(hash, key)
      platform       = key.split(SEP)[2]
      hash[platform] ||= 0
      hash[platform] += 1
      hash
    end

    def config
      Turnstile.config
    end

    def compose_key(uid, platform = nil, ip = nil)
      "#{prefix}#{uid}#{SEP}#{platform}#{SEP}#{ip}"
    end

    private

    def prefix
      @prefix ||= "#{Turnstile::NS}|#{config.redis.namespace.gsub(/#{SEP}/, ':')}#{SEP}"
    end

  end
end
