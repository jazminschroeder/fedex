def fedex_development_credentials
  @fedex_credentials ||= credentials.fetch('development', {})
end

def fedex_production_credentials
  @fedex_production_credentials ||= credentials.fetch('production', {})
end

private

def credentials
  @credentials ||= begin
    YAML.load_file("#{File.dirname(__FILE__)}/../config/fedex_credentials.yml")
  end
end
