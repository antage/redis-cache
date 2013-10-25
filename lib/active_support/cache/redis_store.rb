begin
  require "redis"
rescue LoadError => e
  $stderr.puts "You don't have redis installed in your application. Please add it to your Gemfile and run bundle install"
  raise e
end

require "active_support/time"

module ActiveSupport
  module Cache
    class RedisStore < Store
      def initialize(options = nil)
        super(options)

        options = { :logger => self.class.logger }.merge(options || {})
        if defined?(Hiredis)
          options = { :driver => :hiredis }.merge(options || {})
        end
        @redis = ::Redis.new(options)

        if (@redis.info["redis_version"].split(".").map { |x| x.to_i } <=> [2, 1, 3]) < 0
          $stderr.puts "Redis server with version < 2.1.3 has bug with increment/decrement on values with expiring time! Please upgrade Redis server or don't use increment/decrement methods with :expires_in option."
        end

        extend Strategy::LocalCache
      end

      def reconnect
        @redis and @redis.client.reconnect
      end

      def disconnect
        @redis and @redis.client.disconnect
      end

      def clear(options = nil)
        @redis.flushdb
      end

      def increment(name, amount = 1, options = nil)
        options = merged_options(options)
        expires_in = options[:expires_in].to_i
        redis_key = namespaced_key(name, options)
        response = instrument(:increment, name, :amount => amount) do
          r = @redis.incrby(redis_key, amount)
          if expires_in > 0
            @redis.expire(redis_key, expires_in)
          end
          r
        end
        response
      end

      def decrement(name, amount = 1, options = nil)
        options = merged_options(options)
        expires_in = options[:expires_in].to_i
        redis_key = namespaced_key(name, options)
        response = instrument(:decrement, name, :amount => amount) do
          r = @redis.decrby(redis_key, amount)
          if expires_in > 0
            @redis.expire(redis_key, expires_in)
          end
          r
        end
        response
      end

      def read_multi(*names)
        options = names.extract_options!
        options = merged_options(options)
        keys_to_names = Hash[names.map{|name| [namespaced_key(name, options), name]}]
        raw_values = @redis.mget(*keys_to_names.keys)
        values = {}
        keys_to_names.keys.zip(raw_values).each do |key, value|
          entry = deserialize_entry(value)
          values[keys_to_names[key]] = entry.value unless entry.nil? || entry.expired?
        end
        values
      end

      protected
        def read_entry(key, options)
          deserialize_entry(@redis.get(key))
        end

        def write_entry(key, entry, options)
          method = options && options[:unless_exist] ? :setnx : :set
          value = options[:raw] ? entry.value : Marshal.dump(entry)

          @redis.send(method, key, value)

          expires_in = options[:expires_in].to_i
          if expires_in > 0
            if !options[:raw]
              # Set the redis expire a few minutes in the future to support race condition ttls on read
              expires_in += 5.minutes
            end
            @redis.expire(key, expires_in)
          end
        end

        def delete_entry(key, options)
          @redis.del(key)
        end

      private
        def deserialize_entry(raw_value)
          if raw_value
            entry = Marshal.load(raw_value) rescue raw_value
            entry.is_a?(Entry) ? entry : Entry.new(entry)
          else
            nil
          end
        end
    end
  end
end
