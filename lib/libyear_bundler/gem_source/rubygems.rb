require 'json'
require 'net/http'
require 'uri'

require 'libyear_bundler/gem_source/base'

module LibyearBundler
  module GemSource
    class Rubygems < Base
      def initialize(http)
        @http = http
      end

      def release_date(gem_name, gem_version)
        uri = URI.parse(
          "https://rubygems.org/api/v2/rubygems/#{gem_name}/versions/#{gem_version}.json"
        )
        request = Net::HTTP::Get.new(uri)
        response = @http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          parsed_response = JSON.parse(response.body)
          Date.parse(parsed_response["version_created_at"])
        else
          report_problem(
            gem_name,
            "Release date not found: #{gem_name}: rubygems.org responded with #{response.code}"
          )
          nil
        end
      rescue StandardError => e
        report_problem(gem_name, "Release date not found: #{gem_name}: #{e.inspect}")
        nil
      end

      # docs: http://guides.rubygems.org/rubygems-org-api/#gem-version-methods
      # Versions are returned ordered by version number, descending
      def versions_sequence(gem_name)
        uri = URI.parse("https://rubygems.org/api/v1/versions/#{gem_name}.json")
        request = Net::HTTP::Get.new(uri)
        response = @http.request(request)
        parsed_response = JSON.parse(response.body)
        parsed_response.map { |version| version['number'] }
      end

      private

      def report_problem(gem_name, message)
        @reported_gems ||= {}
        @reported_gems[gem_name] ||= begin
          $stderr.puts(message)
          true
        end
      end
    end
  end
end
