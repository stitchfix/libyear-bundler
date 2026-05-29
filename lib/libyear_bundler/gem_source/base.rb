require 'libyear_bundler/gem_source/problem_reporter'

module LibyearBundler
  module GemSource
    # Abstract interface for a gem source adapter. Concrete subclasses
    # provide the data that `Models::Gem` needs to compute libyears.
    #
    # @api private
    class Base
      # @param _name [String] gem name
      # @param _version [String, Gem::Version]
      # @return [Date, nil] release date of the given version, or nil if
      #   unavailable
      def release_date(_name, _version)
        raise NotImplementedError
      end

      # @param _name [String] gem name
      # @return [Array<String>] all known version strings, sorted descending
      def versions_sequence(_name)
        raise NotImplementedError
      end

      private

      # Reports the first problem encountered for a given gem, and swallows the
      # rest for that gem to avoid spamming the console.
      def report_problem(gem_name, message)
        problem_reporter.report(gem_name, message)
      end

      def problem_reporter
        @problem_reporter ||= ProblemReporter.new(io: $stderr)
      end
    end
  end
end
