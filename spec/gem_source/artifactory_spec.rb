require 'base64'
require 'spec_helper'

module LibyearBundler
  module GemSource
    RSpec.describe Artifactory do
      let(:source_url) { 'https://my-org.jfrog.io/artifactory/api/gems/my-repo/' }
      let(:http) { instance_double(Net::HTTP) }
      let(:source) { described_class.new(source_url, http: http) }

      def stub_aql_response(body)
        response = instance_double(Net::HTTPSuccess, body: body)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(http).to receive(:request) do |req|
          yield(req) if block_given?
          response
        end
        response
      end

      def stub_bundler_credentials(value)
        allow(::Bundler.settings).to receive(:[]).with(source_url).and_return(value)
        allow(::Bundler.settings).to receive(:[]).with('my-org.jfrog.io').and_return(nil)
      end

      describe 'source URL parsing' do
        it 'accepts a custom Artifactory context path and posts AQL to the correct path' do
          custom_url = 'https://stitchfix01.jfrog.io/stitchfix01/api/gems/eng-gems/'
          custom_source = described_class.new(custom_url, http: http)
          allow(custom_source).to receive(:report_problem)
          stub_aql_response('{"results":[{"created":"2024-05-01T12:00:00.000Z"}]}') do |req|
            expect(req.path).to eq('/stitchfix01/api/search/aql')
            expect(req.body).to include(
              'items.find({"name":"private_gem-1.2.3.gem","repo":"eng-gems"})'
            )
          end

          result = custom_source.release_date('private_gem', '1.2.3')

          expect(result).to eq(Date.parse('2024-05-01'))
        end

        it 'raises ArgumentError for URLs that do not match the Artifactory gem source pattern' do
          expect do
            described_class.new('https://my-org.jfrog.io/no-api/here/', http: http)
          end.to raise_error(ArgumentError, /Unrecognized Artifactory source URL/)
        end
      end

      describe '#release_date' do
        it 'returns the created date from AQL for a specific version' do
          stub_aql_response('{"results":[{"created":"2024-05-01T12:00:00.000Z"}]}') do |req|
            expect(req.path).to eq('/artifactory/api/search/aql')
            expect(req.body).to include(
              'items.find({"name":"private_gem-1.2.3.gem","repo":"my-repo"})'
            )
            expect(req.body).to include('.include("created")')
          end

          result = source.release_date('private_gem', '1.2.3')

          expect(result).to eq(Date.parse('2024-05-01'))
        end

        it 'falls back to the gem versions API when AQL returns no artifact' do
          aql_response = instance_double(Net::HTTPSuccess, body: '{"results":[]}')
          allow(aql_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          versions_body = JSON.dump(
            [
              { 'number' => '1.2.3', 'platform' => 'ruby',
                'created_at' => '2024-07-15T10:00:00.000Z' },
              { 'number' => '1.2.2', 'platform' => 'ruby',
                'created_at' => '2024-01-01T10:00:00.000Z' }
            ]
          )
          versions_response = instance_double(Net::HTTPSuccess, body: versions_body)
          allow(versions_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          captured = []
          allow(http).to receive(:request) do |req|
            captured << req
            req.path.include?('/api/search/aql') ? aql_response : versions_response
          end

          result = source.release_date('private_gem', '1.2.3')

          expect(result).to eq(Date.parse('2024-07-15'))
          versions_request = captured.find { |r| r.path.include?('/api/v1/versions/') }
          expect(versions_request).not_to be_nil
          expect(versions_request.method).to eq('GET')
          expect(versions_request.path).to eq(
            '/artifactory/api/gems/my-repo/api/v1/versions/private_gem.json'
          )
        end

        it 'picks the earliest created_at when versions API has multiple platforms' do
          aql_response = instance_double(Net::HTTPSuccess, body: '{"results":[]}')
          allow(aql_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          versions_body = JSON.dump(
            [
              { 'number' => '1.2.3', 'platform' => 'x86_64-linux',
                'created_at' => '2024-07-16T12:00:00.000Z' },
              { 'number' => '1.2.3', 'platform' => 'ruby',
                'created_at' => '2024-07-15T10:00:00.000Z' },
              { 'number' => '1.2.2', 'platform' => 'ruby',
                'created_at' => '2024-01-01T10:00:00.000Z' }
            ]
          )
          versions_response = instance_double(Net::HTTPSuccess, body: versions_body)
          allow(versions_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http).to receive(:request) do |req|
            req.path.include?('/api/search/aql') ? aql_response : versions_response
          end

          expect(source.release_date('private_gem', '1.2.3'))
            .to eq(Date.parse('2024-07-15'))
        end

        it 'reports and returns nil when AQL and versions API both have no match' do
          aql_response = instance_double(Net::HTTPSuccess, body: '{"results":[]}')
          allow(aql_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          versions_body = JSON.dump(
            [{ 'number' => '1.2.2', 'platform' => 'ruby',
               'created_at' => '2024-01-01T10:00:00.000Z' }]
          )
          versions_response = instance_double(Net::HTTPSuccess, body: versions_body)
          allow(versions_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http).to receive(:request) do |req|
            req.path.include?('/api/search/aql') ? aql_response : versions_response
          end
          allow(source).to receive(:report_problem)

          result = source.release_date('private_gem', '1.2.3')

          expect(result).to be_nil
          expect(source).to have_received(:report_problem)
            .with('private_gem', /Release date not found/)
        end

        it 'returns nil and reports when AQL responds with non-2xx' do
          response = instance_double(Net::HTTPNotFound, code: '404', body: '')
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(http).to receive(:request).and_return(response)
          allow(source).to receive(:report_problem)

          result = source.release_date('private_gem', '1.2.3')

          expect(result).to be_nil
          expect(source).to have_received(:report_problem)
            .with('private_gem', /responded with 404 \(no credentials\)/)
        end

        it 'includes response body and credential status when AQL responds with 401' do
          stub_bundler_credentials('alice:secret')
          response = instance_double(
            Net::HTTPUnauthorized,
            code: '401',
            body: '{"errors":[{"status":401,"message":"Wrong username was used"}]}'
          )
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(http).to receive(:request).and_return(response)
          allow(source).to receive(:report_problem)

          result = source.release_date('private_gem', '1.2.3')

          expect(result).to be_nil
          expect(source).to have_received(:report_problem).with(
            'private_gem',
            /responded with 401 \(credentials attached\).*Wrong username was used/
          )
        end
      end

      describe '#versions_sequence' do
        it 'returns deduplicated versions in descending order from AQL results' do
          body = '{"results":[{"name":"rails-7.0.0.gem"},' \
                 '{"name":"rails-7.0.0-x86_64-linux.gem"},{"name":"rails-6.1.0.gem"}]}'
          stub_aql_response(body) do |req|
            expect(req.body).to include(
              'items.find({"name":{"$match":"rails-*.gem"},"repo":"my-repo"})'
            )
            expect(req.body).to include('.include("name")')
          end

          expect(source.versions_sequence('rails')).to eq(['7.0.0', '6.1.0'])
        end

        it 'sorts versions descending by Gem::Version' do
          body = '{"results":[{"name":"widget-1.10.0.gem"},' \
                 '{"name":"widget-2.0.0.gem"},{"name":"widget-10.0.0.gem"}]}'
          stub_aql_response(body)

          expect(source.versions_sequence('widget')).to eq(['10.0.0', '2.0.0', '1.10.0'])
        end
      end

      describe 'authentication' do
        it 'sends Basic auth when Bundler.settings has credentials for the source URL' do
          stub_bundler_credentials('alice:secret')
          allow(source).to receive(:report_problem)
          captured_request = nil
          stub_aql_response('{"results":[]}') { |req| captured_request = req }

          source.release_date('private_gem', '1.2.3')

          expect(captured_request['authorization']).to start_with('Basic ')
          expect(captured_request['authorization']).to include('YWxpY2U6c2VjcmV0') # alice:secret
        end

        it 'sends no Authorization header when Bundler.settings has no credentials' do
          stub_bundler_credentials(nil)
          allow(source).to receive(:report_problem)
          captured_request = nil
          stub_aql_response('{"results":[]}') { |req| captured_request = req }

          source.release_date('private_gem', '1.2.3')

          expect(captured_request['authorization']).to be_nil
        end

        it 'URL-decodes user and password from Bundler.settings before Basic auth' do
          stub_bundler_credentials('user%40example.com:pa%3Ass')
          allow(source).to receive(:report_problem)
          captured_request = nil
          stub_aql_response('{"results":[]}') { |req| captured_request = req }

          source.release_date('private_gem', '1.2.3')

          expect(captured_request['authorization']).to start_with('Basic ')
          expect(captured_request['authorization']).to include(
            ::Base64.strict_encode64('user@example.com:pa:ss')
          )
        end
      end
    end
  end
end
