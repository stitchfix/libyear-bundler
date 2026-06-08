require 'spec_helper'

module LibyearBundler
  module GemSource
    RSpec.describe HttpConnection do
      describe '.for' do
        it 'delegates to the shared cache' do
          cache = instance_spy(HttpConnection::Cache)
          allow(described_class).to receive(:cache).and_return(cache)
          connection = instance_spy(Net::HTTP)
          allow(cache).to receive(:get).with('https://rubygems.org/').and_return(connection)

          expect(described_class.for('https://rubygems.org/')).to eq(connection)
        end
      end

      describe HttpConnection::Cache do
        subject(:cache) { described_class.new }

        let(:url) { 'https://rubygems.org/' }

        describe '#get' do
          it 'returns the same instance on repeated calls' do
            connection = instance_spy(Net::HTTP)
            allow(Net::HTTP).to receive(:start).and_return(connection)

            first = cache.get(url)
            second = cache.get(url)

            expect(first).to eq(second)
            expect(Net::HTTP).to have_received(:start).once
          end

          it 'builds via Net::HTTP.start on miss' do
            connection = instance_spy(Net::HTTP)
            allow(Net::HTTP).to receive(:start)
              .with('rubygems.org', 443, use_ssl: true)
              .and_return(connection)

            expect(cache.get(url)).to eq(connection)
          end
        end

        describe '#set' do
          it 'overrides the stored connection' do
            built = instance_spy(Net::HTTP)
            override = instance_spy(Net::HTTP)
            allow(Net::HTTP).to receive(:start).and_return(built)
            cache.get(url)

            cache.set(url, override)

            expect(cache.get(url)).to eq(override)
            expect(Net::HTTP).to have_received(:start).once
          end
        end

        describe '#clear' do
          it 'calls finish on each cached connection and empties the store' do
            connection = instance_spy(Net::HTTP)
            allow(Net::HTTP).to receive(:start).and_return(connection)
            cache.get(url)

            cache.clear

            expect(connection).to have_received(:finish)
            new_connection = instance_spy(Net::HTTP)
            allow(Net::HTTP).to receive(:start).and_return(new_connection)
            expect(cache.get(url)).to eq(new_connection)
          end

          it 'swallows IOError from already-finished connections' do
            connection = instance_spy(Net::HTTP)
            allow(connection).to receive(:finish).and_raise(IOError)
            allow(Net::HTTP).to receive(:start).and_return(connection)
            cache.get(url)

            expect { cache.clear }.not_to raise_error
          end
        end
      end
    end
  end
end
