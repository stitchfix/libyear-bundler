require 'spec_helper'

module LibyearBundler
  module GemSource
    RSpec.describe Rubygems do
      describe '#release_date' do
        it 'queries rubygems.org API' do
          http = instance_double(Net::HTTP)
          response = instance_double(Net::HTTPSuccess)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body)
            .and_return('{"version_created_at":"2017-01-01T00:00:00Z"}')
          allow(http).to receive(:request).and_return(response)

          source = described_class.new(http)
          result = source.release_date('json', '2.1.0')

          expect(result).to eq(Date.parse('2017-01-01'))
        end
      end
    end
  end
end
