require 'rspec'
require 'fedex'
require 'support/vcr'
require 'support/credentials'
require 'active_support/all'

RSpec.configure do |c|
  c.filter_run_excluding :production unless fedex_production_credentials
end

