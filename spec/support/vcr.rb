require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir  = File.expand_path('../../vcr', __FILE__)
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |c|
  c.include Fedex::Helpers
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.around(:each, :vcr) do |example|
    name = underscorize(example.metadata[:full_description].split(/\s+/, 2).join("/")).gsub(/[^\w\/]+/, "_")
    VCR.use_cassette(name) { example.call }
  end
end
