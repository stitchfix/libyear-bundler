require 'spec_helper'

module LibyearBundler
  module Calculators
    RSpec.describe VersionSequenceDelta do
      describe '#calculate' do
        it 'returns the number of releases between the newest and installed versions' do
          installed_version_sequence_index = 3
          newest_version_sequence_index = 1

          calculation = described_class.calculate(
            installed_version_sequence_index,
            newest_version_sequence_index
          )
          expect(calculation).to eq(2)
        end

        it 'returns zero when either version is missing from the sequence', aggregate_failures: true do
          expect(described_class.calculate(nil, 1)).to eq(0)
          expect(described_class.calculate(3, nil)).to eq(0)
          expect(described_class.calculate(nil, nil)).to eq(0)
        end
      end
    end
  end
end
