require 'spec_helper'
require 'tmpdir'

module LibyearBundler
  RSpec.describe BundleOutdated do
    context 'dependency installed from git' do
      it 'skips the dependency' do
        bundle_outdated = described_class.new('', nil)
        line = "gem_installed_from_git (newest 3.0.0.pre 73d9477, installed 3.0.0.pre 251fb80)"
        allow(bundle_outdated).to receive(:bundle_outdated).and_return(line)
        result = nil
        expect {
          result = bundle_outdated.execute
        }.to output(
          "Skipping gem_installed_from_git because of a malformed version string\n"
        ).to_stderr
        expect(result).to eq([])
      end
    end

    describe '#execute' do
      it 'clears the HttpConnection cache when the loop body raises' do
        bundle_outdated = described_class.new('', nil)
        cache = GemSource::HttpConnection.cache
        allow(cache).to receive(:clear).and_call_original
        allow(bundle_outdated).to receive(:bundle_outdated).and_return("rails (newest 7.0.0, installed 6.1.0)\n")
        allow(GemSource).to receive(:for).and_raise(StandardError, 'boom')

        expect { bundle_outdated.execute }.to raise_error(StandardError, 'boom')
        expect(cache).to have_received(:clear)
      end
    end

    describe '#load_gem_sources' do
      around do |example|
        original_bundle_gemfile = ENV['BUNDLE_GEMFILE']
        example.run
      ensure
        if original_bundle_gemfile
          ENV['BUNDLE_GEMFILE'] = original_bundle_gemfile
        else
          ENV.delete('BUNDLE_GEMFILE')
        end
      end

      it 'loads per-gem sources from Bundler.default_lockfile' do
        Dir.mktmpdir do |tmpdir|
          gemfile = File.join(tmpdir, 'Gemfile')
          lockfile = File.join(tmpdir, 'Gemfile.lock')
          File.write(gemfile, "source 'https://rubygems.org'\n")
          File.write(
            lockfile,
            File.read(File.expand_path('fixtures/github_packages/Gemfile.lock', __dir__))
          )

          ENV['BUNDLE_GEMFILE'] = gemfile
          bundle_outdated = described_class.new(gemfile, nil)
          sources = bundle_outdated.send(:load_gem_sources)

          expect(sources['private_gem1']).to eq('https://rubygems.pkg.github.com/secret_org/')
          expect(sources['json']).to eq('https://rubygems.org/')
        end
      end
    end
  end
end
