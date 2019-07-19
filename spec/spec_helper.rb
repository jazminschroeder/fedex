require 'rspec'
require 'fedex'
require 'support/vcr'
require 'support/credentials'

RSpec.configure do |config|
  config.filter_run_excluding :production if fedex_production_credentials.empty?

  config.expect_with :rspec do |expect_config|
    expect_config.syntax = :expect
  end
end
