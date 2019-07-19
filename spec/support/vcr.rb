# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('../vcr', __dir__)
  config.hook_into :webmock

  config.filter_sensitive_data('FEDEX_DEVELOPMENT_CREDENTIAL_KEY') { fedex_development_credentials[:key] }
  config.filter_sensitive_data('FEDEX_DEVELOPMENT_CREDENTIAL_PASSWORD') { fedex_development_credentials[:password] }
  config.filter_sensitive_data('FEDEX_DEVELOPMENT_CREDENTIAL_ACCOUNT_NUMBER') { fedex_development_credentials[:account_number] }
  config.filter_sensitive_data('FEDEX_DEVELOPMENT_CREDENTIAL_METER') { fedex_development_credentials[:meter] }
  config.filter_sensitive_data('FEDEX_DEVELOPMENT_CREDENTIAL_MODE') { fedex_development_credentials[:mode] }
end

RSpec.configure do |c|
  c.include Fedex::Helpers
  c.around(:each, :vcr) do |example|
    name = underscorize(example.metadata[:full_description].split(/\s+/, 2).join('/')).gsub(/[^\w\/]+/, '_')
    VCR.use_cassette(name, match_requests_on: [:method, :uri, :path, :headers]) { example.call }
  end
end
