# frozen_string_literal: true

require 'spec_helper'

module LibyearBundler
  RSpec.describe ReleaseDateCache do
    describe '.load' do
      it 'has the expected size' do
        cache = described_class.load('spec/fixtures/02/cache.yml')
        expect(cache.size).to eq(2)
      end

      context 'when file does not exist' do
        it 'returns empty cache' do
          cache = described_class.load('/path/that/does/not/exist')
          expect(cache).to be_empty
        end
      end
    end

    describe '#fetch' do
      it 'returns cached value on hit without calling block' do
        date = Date.new(2017, 1, 1)
        cache = described_class.new({ 'json-2.1.0' => date })
        block_called = false

        result = cache.fetch('json', '2.1.0') { block_called = true }

        expect(result).to eq(date)
        expect(block_called).to be false
      end

      it 'yields and stores value on miss' do
        date = Date.new(2017, 1, 1)
        cache = described_class.new({})

        result = cache.fetch('json', '2.1.0') { date }

        expect(result).to eq(date)
        expect(cache.fetch('json', '2.1.0') { raise 'should not be called' }).to eq(date)
      end
    end
  end
end
