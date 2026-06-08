require 'libyear_bundler/gem_source/base'

module LibyearBundler
  module GemSource
    class Unsupported < Base
      def initialize(source_url)
        @source_url = source_url
      end

      def release_date(gem_name, _gem_version)
        report_problem(gem_name, "Skipped: #{gem_name} (unsupported source: #{@source_url})")
        nil
      end

      def versions_sequence(gem_name)
        report_problem(gem_name, "Skipped: #{gem_name} (unsupported source: #{@source_url})")
        []
      end
    end
  end
end
