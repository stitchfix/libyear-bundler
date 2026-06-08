require 'simplecov'
SimpleCov.start

require 'libyear_bundler'
require 'rspec'

Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

require 'webmock/rspec'
WebMock.disable_net_connect!

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.after { LibyearBundler::GemSource::HttpConnection.cache.clear }
end
