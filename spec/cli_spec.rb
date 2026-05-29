require 'spec_helper'
require 'tmpdir'

module LibyearBundler
  RSpec.describe CLI do
    around do |example|
      original_bundle_gemfile = ENV['BUNDLE_GEMFILE']
      ENV.delete('BUNDLE_GEMFILE')
      example.run
    ensure
      if original_bundle_gemfile
        ENV['BUNDLE_GEMFILE'] = original_bundle_gemfile
      else
        ENV.delete('BUNDLE_GEMFILE')
      end
    end

    describe '#initialize' do
      it 'uses the CLI Gemfile argument over BUNDLE_GEMFILE' do
        Dir.mktmpdir do |tmpdir|
          gemfile_a = File.join(tmpdir, 'Gemfile')
          gemfile_b = File.join(tmpdir, 'other.rb')
          File.write(gemfile_a, "source 'https://rubygems.org'\n")
          File.write(gemfile_b, "source 'https://rubygems.org'\n")

          ENV['BUNDLE_GEMFILE'] = gemfile_a
          cli = described_class.new([gemfile_b])

          expect(cli.instance_variable_get(:@gemfile_path)).to eq(File.expand_path(gemfile_b))
          expect(ENV['BUNDLE_GEMFILE']).to eq(File.expand_path(gemfile_b))
        end
      end

      it 'honors BUNDLE_GEMFILE when no Gemfile argument is given' do
        Dir.mktmpdir do |tmpdir|
          gemfile = File.join(tmpdir, 'Gemfile')
          File.write(gemfile, "source 'https://rubygems.org'\n")

          ENV['BUNDLE_GEMFILE'] = gemfile
          cli = described_class.new([])

          expect(cli.instance_variable_get(:@gemfile_path)).to eq(File.expand_path(gemfile))
        end
      end

      it 'resolves the default Gemfile when no argument or env var is set' do
        cli = described_class.new([])

        expect(cli.instance_variable_get(:@gemfile_path)).to eq(
          File.expand_path('Gemfile', Dir.pwd)
        )
      end

      it 'exits with E_NO_GEMFILE when Bundler cannot find a Gemfile' do
        allow(Bundler).to receive(:default_gemfile).and_raise(
          Bundler::GemfileNotFound,
          'Could not locate Gemfile'
        )

        expect {
          described_class.new([])
        }.to raise_error(SystemExit) { |error| expect(error.status).to eq(described_class::E_NO_GEMFILE) }
          .and output("Could not locate Gemfile\n").to_stderr
      end
    end
  end
end
