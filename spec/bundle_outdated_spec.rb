require 'spec_helper'

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
  end
end
