require 'cgi'
require 'date'
require 'json'
require 'net/http'
require 'uri'

require 'libyear_bundler/gem_source/base'
require 'libyear_bundler/gem_source/http_connection'

module LibyearBundler
  module GemSource
    class Artifactory < Base
      SOURCE_URL_PATTERN =
        %r{\A(https?://[^/]+\.jfrog\.io/[^/]+)/api/gems/([^/]+)/?\z}.freeze

      def initialize(source_url)
        @source_url = source_url
        parse_source_url(source_url)
      end

      def release_date(gem_name, gem_version)
        body = release_date_aql(gem_name, gem_version)
        response = aql_post(body)
        unless response.is_a?(Net::HTTPSuccess)
          report_problem(
            gem_name,
            "Release date not found: #{gem_name}: #{http_error_detail(response)}"
          )
          return nil
        end

        results = JSON.parse(response.body)['results']
        if results.nil? || results.empty?
          fallback = release_date_from_versions_api(gem_name, gem_version)
          return fallback if fallback

          report_problem(gem_name, "Release date not found: #{gem_name}")
          return nil
        end

        Date.parse(results.first['created'])
      rescue StandardError => e
        report_problem(gem_name, "Release date not found: #{gem_name}: #{e.inspect}")
        nil
      end

      def versions_sequence(gem_name)
        body = versions_sequence_aql(gem_name)
        response = aql_post(body)
        unless response.is_a?(Net::HTTPSuccess)
          report_problem(
            gem_name,
            "Versions not found: #{gem_name}: #{http_error_detail(response)}"
          )
          return []
        end

        results = JSON.parse(response.body)['results'] || []
        versions = results.map { |item| extract_version(item['name'], gem_name) }.compact.uniq
        versions.sort_by { |v| Gem::Version.new(v) }.reverse
      rescue StandardError => e
        report_problem(gem_name, "Versions not found: #{gem_name}: #{e.inspect}")
        []
      end

      private

      def parse_source_url(source_url)
        match = source_url.match(SOURCE_URL_PATTERN)
        raise ArgumentError, "Unrecognized Artifactory source URL: #{source_url}" unless match

        @artifactory_base = match[1]
        @repo_key = match[2]
        @host = URI.parse(@artifactory_base).host
      end

      def release_date_aql(gem_name, gem_version)
        %(items.find({"name":"#{gem_name}-#{gem_version}.gem","repo":"#{@repo_key}"}).include("created"))
      end

      def versions_sequence_aql(gem_name)
        %(items.find({"name":{"$match":"#{gem_name}-*.gem"},"repo":"#{@repo_key}"}).include("name"))
      end

      def aql_post(body)
        uri = URI.parse("#{@artifactory_base}/api/search/aql")
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'text/plain'
        request.body = body
        apply_credentials(request)
        http_client.request(request)
      end

      def release_date_from_versions_api(gem_name, gem_version)
        uri = URI.parse("#{@source_url.chomp('/')}/api/v1/versions/#{gem_name}.json")
        request = Net::HTTP::Get.new(uri)
        apply_credentials(request)
        response = http_client.request(request)
        return nil unless response.is_a?(Net::HTTPSuccess)

        versions = JSON.parse(response.body)
        return nil unless versions.is_a?(Array)

        matches = versions.select { |v| v['number'].to_s == gem_version.to_s }
        return nil if matches.empty?

        earliest = matches.min_by { |v| v['created_at'].to_s }
        created = earliest['created_at']
        created && Date.parse(created)
      rescue StandardError
        nil
      end

      def apply_credentials(request)
        return unless credentials

        user, password = credentials.split(':', 2).map { |part| CGI.unescape(part) }
        request.basic_auth(user, password)
      end

      def http_error_detail(response)
        creds_status = credentials ? 'credentials attached' : 'no credentials'
        detail = "#{@host} responded with #{response.code} (#{creds_status})"
        body_excerpt = response.body.to_s.strip
        return detail if body_excerpt.empty?

        excerpt = body_excerpt.length > 200 ? "#{body_excerpt[0, 200]}..." : body_excerpt
        "#{detail}: #{excerpt}"
      end

      def credentials
        credentials_from_env || ::Bundler.settings[@source_url] || ::Bundler.settings[@host]
      end

      def credentials_from_env
        key = @host.gsub(".", "__").gsub("-", "___").upcase
        ENV["BUNDLE_#{key}"]
      end

      def http_client
        HttpConnection.for(@source_url)
      end

      def extract_version(filename, gem_name)
        prefix = "#{gem_name}-"
        return nil unless filename.end_with?('.gem') && filename.start_with?(prefix)

        version_part = filename[prefix.length..-5]
        return nil if version_part.nil? || version_part.empty?

        parse_version_from_filename_tail(version_part)
      end

      # Given the portion of a `.gem` filename after `name-`, returns the
      # leading semver (e.g. `7.0.0` from `7.0.0-x86_64-linux`). Ignores
      # unrelated artifacts that share a prefix (e.g. `datadog-ruby_core_source`
      # when the gem name is `datadog`).
      def parse_version_from_filename_tail(version_part)
        segments = version_part.split('-')
        segments.length.times do |i|
          candidate = segments[0, i + 1].join('-')
          return candidate if Gem::Version.correct?(candidate)
        end
        nil
      end
    end
  end
end
