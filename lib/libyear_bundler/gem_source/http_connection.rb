require 'net/http'
require 'uri'

module LibyearBundler
  module GemSource
    # Process-wide cache of started Net::HTTP connections keyed by source URL,
    # shared across gem source adapters so requests within a single bundler
    # run reuse one TCP/TLS session per host.
    #
    # @api private
    class HttpConnection
      # Returns the Net::HTTP connection from the cache for the given `source_url`.
      #
      # @param source_url [String]
      # @return [Net::HTTP] An open connection to the given source URL.
      def self.for(source_url)
        cache.get(source_url)
      end

      # Singleton cache. Exposed as a test seam: specs preload via `set` and
      # reset via `clear`.
      #
      # @return [Cache]
      def self.cache
        @cache ||= Cache.new
      end

      # Hash-backed store of `source_url => Net::HTTP`. Will create a new
      # connection if one is not found in the cache. Invoking `clear` will
      # close all connections and empty the cache.
      #
      # @api private
      class Cache
        def initialize
          @store = Hash.new { |hash, key| hash[key] = build(key) }
        end

        # @param url [String]
        # @return [Net::HTTP] cached or freshly-built connection for `url`
        def get(url)
          @store[url]
        end

        # Assigns the cached connection for a given `url`.
        #
        # @param url [String]
        # @param connection [Net::HTTP]
        def set(url, connection)
          @store[url] = connection
        end

        # Calls `finish` on every cached connection, and clears the cache.
        def clear
          @store.each_value do |connection|
            begin
              connection.finish if connection.respond_to?(:finish)
            rescue IOError
              # already closed
            end
          end
          @store.clear
        end

        private

        # Starts a new Net::HTTP for `url`. The returned connection is open
        # and owned by the cache.
        def build(url)
          uri = URI.parse(url)
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https')
        end
      end
    end
  end
end
