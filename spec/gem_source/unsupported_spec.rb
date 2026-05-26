require 'spec_helper'

module LibyearBundler
  module GemSource
    RSpec.describe Unsupported do
      describe '#release_date' do
        it 'returns nil and reports skipped' do
          source = described_class.new('https://custom.gem.server/')
          allow(source).to receive(:report_problem)

          result = source.release_date('private_gem', '1.0.0')

          expect(result).to be_nil
          expect(source).to have_received(:report_problem)
            .with('private_gem', /skipped.*unsupported source/i)
        end
      end
    end
  end
end
