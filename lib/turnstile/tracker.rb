module Turnstile
  class Tracker
    def sample(uid, platform = 'unknown', ip = nil)
      adapter.add(uid, platform, ip) if sampler.sample(uid)
    end

    alias track sample

    def add(uid, platform = 'unknown', ip = nil)
      adapter.add(uid, platform, ip)
    end

    def add_token(token, delimiter = ':')
      platform, ip, uid = token.split(delimiter)
      adapter.add(uid, platform, ip) if uid
    end

    private

    def adapter
      @adapter ||= Adapter.new
    end

    def sampler
      @sampler ||= Sampler.new
    end
  end
end
