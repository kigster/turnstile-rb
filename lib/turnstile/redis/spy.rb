module Turnstile
  module Redis
    class Spy < Struct.new(:redis)
      @stream        = STDOUT
      @disable_color = false

      class << self
        # in case someone might prefer STDERR, feel free to set
        # it in the gem configuration:
        # SimpleFeed::Providers::Redis::Driver::LoggingRedis.stream = STDOUT | STDERR | etc...
        attr_accessor :stream, :disable_color
      end


      def method_missing(m, *args, &block)
        if redis.respond_to?(m)
          t1     = Time.now
          result = redis.send(m, *args, &block)
          delta  = Time.now - t1
          colors = [:blue, nil, :blue, :blue, :yellow, :cyan, nil, :blue]

          components = [
            Time.now.strftime('%H:%M:%S.%L'), ' rtt=',
            (sprintf '%.5f', delta*1000), ' ms ',
            (sprintf '%15s ', m.to_s.upcase),
            (sprintf '%-40s', args.inspect.gsub(/[",\[\]]/, '')), ' ⇒ ',
            (result.is_a?(::Redis::Future) ? '' : result.to_s)]

          components.each_with_index do |component, index|
            color     = self.class.disable_color ? nil : colors[index]
            component = component.send(color) if color
            self.class.stream.printf component
          end
          self.class.stream.puts
          result
        else
          super
        end
      end
    end
  end
end
