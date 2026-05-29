# frozen_string_literal: true

require 'stringio'

module GemSourceSpecHelpers
  # Builds a gem source with a {LibyearBundler::GemSource::ProblemReporter}
  # wired to +problems_io+ (typically a {StringIO} in specs).
  def build_gem_source(klass, *args, problems_io: StringIO.new)
    source = klass.new(*args)
    source.problem_reporter = LibyearBundler::GemSource::ProblemReporter.new(io: problems_io)
    source
  end
end

RSpec.configure do |config|
  config.include GemSourceSpecHelpers
end
