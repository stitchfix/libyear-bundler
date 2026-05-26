require 'spec_helper'

module LibyearBundler
  module GemSource
    RSpec.describe GithubPackages do
      describe '#release_date' do
        context 'when gh CLI is available' do
          it 'queries GitHub API via gh CLI' do
            allow(described_class).to receive(:gh_available?).and_return(true)
            source = described_class.new('https://rubygems.pkg.github.com/secret_org/')
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
            source = described_class.new('https://rubygems.pkg.github.com/secret_org/')
            allow(source).to receive(:report_problem)

            result = source.release_date('private_gem1', '2.6.0')

            expect(result).to be_nil
            expect(source).to have_received(:report_problem)
              .with('private_gem1', /skipped.*private source/i)
          end
        end
      end

      describe '#versions_sequence' do
        it 'raises NotImplementedError' do
          source = described_class.new('https://rubygems.pkg.github.com/secret_org/')

          expect { source.versions_sequence('private_gem1') }
            .to raise_error(NotImplementedError, /not supported for GitHub Packages/)
        end
      end

      describe '.gh_available?' do
        it 'returns true when gh command exists' do
          allow(described_class).to receive(:system)
            .with('which gh > /dev/null 2>&1')
            .and_return(true)

          expect(described_class.gh_available?).to be true
        end

        it 'returns false when gh command does not exist' do
          allow(described_class).to receive(:system)
            .with('which gh > /dev/null 2>&1')
            .and_return(false)

          expect(described_class.gh_available?).to be false
        end
      end
    end
  end
end
