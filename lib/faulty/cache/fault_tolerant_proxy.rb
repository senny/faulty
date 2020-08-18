# frozen_string_literal: true

module Faulty
  module Cache
    # A wrapper for cache backends that may raise errors
    #
    # If the cache backend raises a `StandardError`, it will be captured and
    # sent to the notifier.
    class FaultTolerantProxy
      # @!attribute [r] notifier
      #   @return [Events::Notifier] A Faulty notifier
      Options = Struct.new(
        :notifier
      ) do
        include ImmutableOptions

        private

        def required
          %i[notifier]
        end
      end

      # @param cache [Cache::Interface] The cache backend to wrap
      # @param options [Hash] Attributes for {Options}
      # @yield [Options] For setting options in a block
      def initialize(cache, **options, &block)
        @cache = cache
        @options = Options.new(options, &block)
      end

      # Read from the cache safely
      #
      # If the backend raises a `StandardError`, this will return `nil`.
      #
      # @param (see Cache::Interface#read)
      # @return [Object, nil] The value if found, or nil if not found or if an
      #   error was raised.
      def read(key)
        @cache.read(key)
      rescue StandardError => e
        options.notifier.notify(:cache_failure, key: key, action: :read, error: e)
        nil
      end

      # Write to the cache safely
      #
      # If the backend raises a `StandardError`, the write will be ignored
      #
      # @param (see Cache::Interface#write)
      # @return [void]
      def write(key, value, expires_in: nil)
        @cache.write(key, value, expires_in: expires_in)
      rescue StandardError
        options.notifier.notify(:cache_failure, key: key, action: :write, error: e)
        nil
      end
    end
  end
end
