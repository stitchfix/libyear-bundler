# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

module LibyearBundler
  module GemSource
    RSpec.describe GithubPackages do
      let(:problems) { StringIO.new }
      let(:source_url) { 'https://rubygems.pkg.github.com/secret_org/' }
      let(:source) { build_gem_source(described_class, source_url, problems_io: problems) }

      describe '#release_date' do
        context 'when gh CLI is available' do
          it 'queries GitHub API via gh CLI' do
            allow(described_class).to receive(:gh_available?).and_return(true)
            allow(source).to receive(:gh_api_call)
              .with('/orgs/secret_org/packages/rubygems/private_gem1/versions')
              .and_return(['[{"name":"2.6.0","created_at":"2025-11-18T22:27:39Z"}]', true])

            result = source.release_date('private_gem1', '2.6.0')

            expect(result).to eq(Date.parse('2025-11-18'))
          end
        end

        context 'when gh CLI is not available' do
          it 'returns nil and does not query' do
            allow(described_class).to receive(:gh_available?).and_return(false)

            result = source.release_date('private_gem1', '2.6.0')

            expect(result).to be_nil
            expect(problems.string).to match(/skipped.*private_gem1.*private source/i)
          end
        end
      end

      describe '#versions_sequence' do
        context 'when gh CLI is not available' do
          it 'returns an empty array and reports skipped' do
            allow(described_class).to receive(:gh_available?).and_return(false)

            result = source.versions_sequence('private_gem1')

            expect(result).to eq([])
            expect(problems.string).to match(/skipped.*private_gem1.*private source/i)
          end
        end

        context 'when gh CLI is available' do
          it 'returns an empty array and reports that releases are unsupported' do
            allow(described_class).to receive(:gh_available?).and_return(true)

            result = source.versions_sequence('private_gem1')

            expect(result).to eq([])
            expect(problems.string).to match(/releases metric is not supported/i)
          end
        end
      end

      describe '.gh_available?' do
        it 'returns true when gh command exists' do
          # https://docs.ruby-lang.org/en/master/Open3.html#method-i-capture2
          # `capture2` returns an array [output, Process::Status]
          allow(Open3).to receive(:capture2)
            .with("which gh > /dev/null 2>&1")
            .and_return(["", instance_spy(Process::Status, success?: true)])

          expect(described_class.gh_available?).to be true
        end

        it 'returns false when gh command does not exist' do
          # https://docs.ruby-lang.org/en/master/Open3.html#method-i-capture2
          # `capture2` returns an array [output, Process::Status]
          allow(Open3).to receive(:capture2)
            .with("which gh > /dev/null 2>&1")
            .and_return(["", instance_spy(Process::Status, success?: false)])

          expect(described_class.gh_available?).to be false
        end
      end
    end
  end
end
