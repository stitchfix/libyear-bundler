require 'set'

module LibyearBundler
  module GemSource
    # Writes problem messages to an IO, deduplicated per gem so that a
    # single gem failing both `release_date` and `versions_sequence` (or
    # falling through multiple fallback paths) only produces one line.
    #
    # @api private
    class ProblemReporter
      # @param io [IO] sink for problem messages, typically $stderr
      def initialize(io:)
        @reported_gems = Set.new
        @io = io
      end

      # Prints `message` unless `gem_name` has already been reported by this
      # instance.
      #
      # @param gem_name [String]
      # @param message [String]
      def report(gem_name, message)
        return if @reported_gems.include?(gem_name)
        @reported_gems.add(gem_name)
        @io.puts(message)
      end
    end
  end
end
