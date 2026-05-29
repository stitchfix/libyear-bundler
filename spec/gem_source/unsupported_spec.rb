# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

module LibyearBundler
  module GemSource
    RSpec.describe Unsupported do
      let(:problems) { StringIO.new }
      let(:source_url) { 'https://custom.gem.server/' }
      let(:source) { build_gem_source(described_class, source_url, problems_io: problems) }

      describe '#release_date' do
        it 'returns nil and reports skipped' do
          result = source.release_date('private_gem', '1.0.0')

          expect(result).to be_nil
          expect(problems.string).to match(/skipped.*private_gem.*unsupported source/i)
        end
      end

      describe '#versions_sequence' do
        it 'returns an empty array and reports skipped' do
          result = source.versions_sequence('private_gem')

          expect(result).to eq([])
          expect(problems.string).to match(/skipped.*private_gem.*unsupported source/i)
        end
      end
    end
  end
end
