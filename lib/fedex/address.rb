module Fedex
  class Address

    attr_reader :changes, :score, :confirmed, :available, :status, :residential,
                :business, :street_lines, :city, :state, :province_code,
                :postal_code, :country_code

    def initialize(options)
      @changes   = options[:changes]
      @score     = options[:score].to_i
      @confirmed = options[:delivery_point_validation] == "CONFIRMED"
      @available = options[:delivery_point_validation] != "UNAVAILABLE"

      @status      = options[:residential_status]
      @residential = status == "RESIDENTIAL"
      @business    = status == "BUSINESS"

      address        = options[:address]

      @street_lines  = address[:street_lines]
      @city          = address[:city]
      @state         = address[:state_or_province_code]
      @province_code = address[:state_or_province_code]
      @postal_code   = address[:postal_code]
      @country_code  = address[:country_code]

      @options = options
    end
  end
end