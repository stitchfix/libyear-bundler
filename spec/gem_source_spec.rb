require 'spec_helper'

module LibyearBundler
  RSpec.describe GemSource do
    describe '.for' do
      it 'returns Rubygems for rubygems.org' do
        http = instance_double(Net::HTTP)

        source = described_class.for('https://rubygems.org/', http)

        expect(source).to be_a(GemSource::Rubygems)
      end

      it 'returns GithubPackages for GitHub Packages URLs' do
        http = instance_double(Net::HTTP)

        source = described_class.for('https://rubygems.pkg.github.com/secret_org/', http)

        expect(source).to be_a(GemSource::GithubPackages)
      end

      it 'returns Artifactory for *.jfrog.io URLs' do
        http = instance_double(Net::HTTP)

        source = described_class.for(
          'https://my-org.jfrog.io/artifactory/api/gems/my-repo/', http
        )

        expect(source).to be_a(GemSource::Artifactory)
      end

      it 'returns Unsupported for unknown sources' do
        http = instance_double(Net::HTTP)

        source = described_class.for('https://custom.gem.server/', http)

        expect(source).to be_a(GemSource::Unsupported)
      end
    end
  end
end
