require 'fedex/credentials'
require 'fedex/request/pickup'

module Fedex
  class Pickup

    # In order to use Fedex pickup API you must first apply for a developer(and later production keys),
    # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - Fedex web service key
    # @param [String] password - Fedex password
    # @param [String] account_number - Fedex account_number
    # @param [String] meter - Fedex meter number
    # @param [String] mode - [development/production]
    #
    # return a Fedex::Pickup object
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    # Compulsory parameters for a successful Pickup Request (key<>value pairs of options hash)
    #
    # @param [String] contact_name, A string containing pickup contact person's name
    # @param [String] company_name, A string containing pickup company's name
    # @param [String] phone_number, A string containing pickup contact phone number
    # @param [Array] address, An array containing address street lines as strings
    # @param [String] city, A string containing pickup city
    # @param [String] state, A string containing state or provice code
    # @param [String] postal_code, A string containing pickup location's postal code
    # @param [String] country, A string containing pickup location's country code (e.g. IT for Italy)
    # @param [Decimal] total_weight, A decimal value for total weight of picked up packages
    # @param [Integer] package_count, An integer for number of packages to be picked up
    # @param [String] ready_time_stamp, A utc timestamp as string to signify when packages are ready, e.g. "2014-09-22T13:20:18+03:00"
    # @param [String] company_close_time, A string to signify what local time pickup point (company) closes, formatted as "HH:MM:SS"
    #
    #
    # Optional parameters
    #
    # @param [Integer] oversize_package_count, An integer for number of oversize packages to be picked up
    # @param [String] carrier_code, A valid fedex carrier code, defaults to FDXE if not given
    # @param [String] weight_unit, A valid weight unit, defaults to "KG" if not given
    # @param [String] package_location, A string to signify package location, refer to Fedex documentation for valid values
    # @param [String] building_part, A string to signify building part, refer to Fedex documentation for valid values
    # @param [String] building_part_description, A string to signify building part description, refer to Fedex documentation for valid values
    # @param [String] remarks, A string for free text remarks to the pickup driver
    def pickup(options = {})
      Request::Pickup.new(@credentials, options).process_request
    end

  end
end
