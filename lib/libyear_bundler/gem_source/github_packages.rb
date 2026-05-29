require 'English'
require 'json'

require 'libyear_bundler/gem_source/base'

module LibyearBundler
  module GemSource
    class GithubPackages < Base
      def initialize(source_url)
        @source_url = source_url
        @org = source_url.split('/').last.delete('/')
      end

      def release_date(gem_name, gem_version)
        unless gh_available?
          report_problem(gem_name, "Skipped: #{gem_name} (private source, gh CLI not available)")
          return nil
        end

        output, success = gh_api_call("/orgs/#{@org}/packages/rubygems/#{gem_name}/versions")
        return nil unless success

        versions = JSON.parse(output)
        version_data = versions.find { |v| v['name'] == gem_version.to_s }
        return nil unless version_data

        Date.parse(version_data['created_at'])
      rescue StandardError => e
        report_problem(gem_name, "Release date not found: #{gem_name}: #{e.inspect}")
        nil
      end

      def versions_sequence(gem_name)
        unless gh_available?
          report_problem(gem_name, "Skipped: #{gem_name} (private source, gh CLI not available)")
          return []
        end

        report_problem(
          gem_name,
          "Skipped: #{gem_name} (releases metric is not supported for GitHub Packages)"
        )
        []
      end

      def self.gh_available?
        system('which gh > /dev/null 2>&1')
      end

      private

      def gh_available?
        self.class.gh_available?
      end

      def gh_api_call(endpoint)
        output = `gh api #{endpoint} 2>&1`
        [output, $CHILD_STATUS.success?]
      end
    end
  end
end
