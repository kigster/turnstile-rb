require_relative 'adapter'
require_relative 'adapter'

module Turnstile
  class Tracker

    def track_and_sample(uid, platform = 'unknown', ip = nil)
      track_all(uid, platform, ip) if should_track?(uid)
    end

    def should_track?(uid)
      !sampler.sampling? || sampler.sample(uid)
    end

    def track_all(uid, platform = 'unknown', ip = nil)
      adapter.add(uid, platform, ip)
    end

    def track_token(token, delimiter = ':')
      platform, ip, uid = token.split(delimiter)
      adapter.add(uid, platform, ip) if uid
    end

    alias track track_and_sample

    private

    def adapter
      @adapter ||= Adapter.new
    end

    def sampler
      @sampler ||= Sampler.new
    end
  end
end
