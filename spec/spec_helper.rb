# frozen_string_literal: true

require 'rspec'
require 'fedex'
require 'support/vcr'
require 'support/credentials'

require 'dotenv'

Dotenv.load

RSpec.configure do |config|
  config.filter_run_excluding :production unless ENV['RUN_PRODUCTION_SPECS']

  config.expect_with :rspec do |expect_config|
    expect_config.syntax = :expect
  end
end
