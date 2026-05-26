require 'spec_helper'
require 'stringio'

module LibyearBundler
  module GemSource
    RSpec.describe ProblemReporter do
      describe '#report' do
        it 'only reports the first message for a given gem' do
          io = StringIO.new
          reporter = described_class.new(io: io)

          reporter.report('some_gem', 'first problem')
          reporter.report('some_gem', 'second problem')

          expect(io.string).to eq("first problem\n")
        end

        it 'reports problems for different gems independently' do
          io = StringIO.new
          reporter = described_class.new(io: io)

          reporter.report('gem_a', 'problem with a')
          reporter.report('gem_b', 'problem with b')

          expect(io.string).to eq("problem with a\nproblem with b\n")
        end
      end
    end
  end
end
