require 'spec_helper'
require 'tmpdir'

module LibyearBundler
  RSpec.describe BundleOutdated do
    context 'dependency installed from git' do
      it 'skips the dependency' do
        bundle_outdated = described_class.new(_gemfile_path = '', _gemfile_lock_path = '')
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
      it 'passes the bundler env to Open3.capture3' do
        bundle_outdated = described_class.new('/path/Gemfile', '/path/Gemfile.lock')
        status = instance_double(Process::Status, to_i: 0)
        expect(Open3).to receive(:capture3).with(
          { 'BUNDLE_GEMFILE' => '/path/Gemfile', 'BUNDLE_LOCKFILE' => '/path/Gemfile.lock' },
          'bundle outdated --parseable'
        ).and_return(['', '', status])

        bundle_outdated.execute
      end

      it 'clears the HttpConnection cache when the loop body raises' do
        bundle_outdated = described_class.new(_gemfile_path = '', _gemfile_lock_path = '')
        cache = GemSource::HttpConnection.cache
        allow(cache).to receive(:clear).and_call_original
        allow(bundle_outdated).to receive(:bundle_outdated).and_return("rails (newest 7.0.0, installed 6.1.0)\n")
        allow(GemSource).to receive(:for).and_raise(StandardError, 'boom')

        expect { bundle_outdated.execute }.to raise_error(StandardError, 'boom')
        expect(cache).to have_received(:clear)
      end
    end

    describe '#load_gem_sources' do
      it 'loads per-gem sources from the lockfile path' do
        Dir.mktmpdir do |tmpdir|
          gemfile = File.join(tmpdir, 'Gemfile')
          lockfile = File.join(tmpdir, 'Gemfile.lock')
          File.write(gemfile, "source 'https://rubygems.org'\n")
          File.write(
            lockfile,
            File.read(File.expand_path('fixtures/github_packages/Gemfile.lock', __dir__))
          )

          bundle_outdated = described_class.new(gemfile, lockfile)
          status = instance_double(Process::Status, to_i: 0)
          allow(Open3).to receive(:capture3).and_return(
            ["private_gem1 (newest 2.0.0, installed 1.0.0)\n", '', status]
          )
          expect(GemSource).to receive(:for).with('https://rubygems.pkg.github.com/secret_org/').and_call_original
          allow(GemSource).to receive(:for).and_call_original

          bundle_outdated.execute
        end
      end
    end
  end
end
