# frozen_string_literal: true

module Pilipinas
  # Thread-safe, process-lifetime in-memory cache.
  #
  # YAML data files are large (42 k+ barangay records). {Cache} ensures each
  # file is parsed exactly once per process and the result is reused for every
  # subsequent look-up. Double-checked locking keeps mutex contention minimal
  # in concurrent environments.
  #
  # @example
  #   value = Pilipinas::Cache.fetch("my_key") { expensive_computation }
  #
  # @api private
  module Cache
    @store = {}
    @mutex = Mutex.new

    class << self
      # Return the cached value for +key+, computing it via +block+ on the
      # first invocation.
      #
      # @param key [String] unique cache key
      # @yield  called once, the return value is stored and returned
      # @return [Object] the cached (or freshly computed) value
      def fetch(key)
        # Fast path: no locking when the key is already present.
        return @store[key] if @store.key?(key)

        @mutex.synchronize do
          # Second check inside the lock to prevent duplicate computation.
          @store[key] = yield unless @store.key?(key)
          @store[key]
        end
      end

      # Evict every cached entry.
      #
      # Primarily useful between test examples to ensure isolation.
      #
      # @return [void]
      def clear
        @mutex.synchronize { @store.clear }
      end

      # Returns a snapshot of all currently cached keys.
      #
      # @return [Array<String>]
      def keys
        @mutex.synchronize { @store.keys.dup }
      end

      # Returns the number of cached entries.
      #
      # @return [Integer]
      def size
        @mutex.synchronize { @store.size }
      end
    end
  end
end
