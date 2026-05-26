require 'set'

module LibyearBundler
  module GemSource
    class ProblemReporter
      def initialize(io:)
        @reported_gems = Set.new
        @io = io
      end

      def report(gem_name, message)
        return if @reported_gems.include?(gem_name)
        @reported_gems.add(gem_name)
        @io.puts(message)
      end
    end
  end
end
