require 'libyear_bundler/gem_source/problem_reporter'

module LibyearBundler
  module GemSource
    class Base
      def release_date(_name, _version)
        raise NotImplementedError
      end

      def versions_sequence(_name)
        raise NotImplementedError
      end

      private

      def report_problem(gem_name, message)
        problem_reporter.report(gem_name, message)
      end

      def problem_reporter
        @problem_reporter ||= ProblemReporter.new(io: $stderr)
      end
    end
  end
end
