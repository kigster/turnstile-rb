require 'timeout'
require 'colored2'
require_relative 'adapter'

module Turnstile
  module Redis
    module Connection
      include Timeout

      attr_accessor :config

      def exec(redis_method, *args, &block)
        send_proc = redis_method if redis_method.respond_to?(:call)
        send_proc ||= ->(redis) { redis.send(redis_method, *args, &block) }
        with_redis { |redis| send_proc.call(redis) }
      end

      %i(set get incr decr setex expire del setnx exists zadd zrange flushdb).each do |method|
        define_method(method) do |*args|
          self.exec method, *args
        end
      end

      def with_redis
        with_retries do
          pool.with do |redis|
            yield(Turnstile.debug? ? LoggingRedis.new(redis) : redis)
          end
        end
      end

      def with_pipelined
        with_retries do
          with_redis do |redis|
            redis.pipelined do
              yield(redis)
            end
          end
        end
      end

      def with_multi
        with_retries do
          with_redis do |redis|
            redis.multi do
              yield(redis)
            end
          end
        end
      end

      def with_retries(tries = 3)
        yield(tries)
      rescue Errno::EINVAL => e
        on_error e
      rescue ::Redis::BaseConnectionError => e
        if (tries -= 1) > 0
          sleep rand(0..0.01)
          retry
        else
          on_error e
        end
      rescue ::Redis::CommandError => e
        (e.message =~ /loading/i || e.message =~ /connection/i) ? on_error(e) : raise(e)
      end

      # This is how we'll be creating redis; depending on input arguments:
      def redis_proc
        @redis_proc ||= (config.redis.url ? redis_proc_from_url : redis_proc_from_opts)
      end

      # Connection pool to the Redis server
      def pool
        @pool ||= ::ConnectionPool.new(size: config.redis.pool_size, &redis_proc)
      end

      def on_error(e)
        raise Error.new(e)
      end

      def redis_proc_from_url
        @redis_proc_from_url ||= proc do
          ::Redis.new(redis_opts(url: config.redis.url)).tap do |conn|
            log_connection(conn)
          end
        end
      end

      def redis_opts(opts)
        opts.tap do |hash|
          hash[:driver] = 'hiredis' if config.redis_use_hiredis
        end
      end

      def redis_proc_from_opts
        @redis_proc_from_opts ||= proc {
          ::Redis.new(redis_opts(host: config.redis.host,
                                 port: config.redis.port,
                                 db:   config.redis.db)).tap do |conn|
            log_connection(conn)
          end
        }
      end

      private

      def log_connection(conn)
        if config.trace
          tdb "created a new redis connection: #{conn}"
          tdb "driver: #{conn.instance_variable_get(:@client).driver}"
        end
      end
    end
  end
end

