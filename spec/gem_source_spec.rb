require 'spec_helper'

module LibyearBundler
  RSpec.describe GemSource do
    describe '.for' do
      it 'returns Rubygems for rubygems.org' do
        source = described_class.for('https://rubygems.org/')

        expect(source).to be_a(GemSource::Rubygems)
      end

      it 'returns GithubPackages for GitHub Packages URLs' do
        source = described_class.for('https://rubygems.pkg.github.com/secret_org/')

        expect(source).to be_a(GemSource::GithubPackages)
      end

      it 'returns Artifactory for *.jfrog.io URLs' do
        source = described_class.for(
          'https://my-org.jfrog.io/artifactory/api/gems/my-repo/'
        )

        expect(source).to be_a(GemSource::Artifactory)
      end

      it 'returns Unsupported for unknown sources' do
        source = described_class.for('https://custom.gem.server/')

        expect(source).to be_a(GemSource::Unsupported)
      end
    end
  end
end
