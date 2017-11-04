module Turnstile
  module Collector
    class Session < ::Struct.new(:uid, :platform, :ip);
    end
  end
end

