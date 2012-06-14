module Fedex
  module Helpers

    private
    # String or :symbol to CamelCase
    def camelize(s)
      # s.to_s.split('_').map { |e| e.capitalize }.join('')
      s.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    # Helper method to validate required fields
    def requires!(hash, *params)
       params.each { |param| raise RateError, "Missing Required Parameter #{param}" if hash[param].nil? }
    end

    def underscorize(key) #:nodoc:
      key.to_s.sub(/^(v[0-9]+|ns):/, "").gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
    end
  end
end
