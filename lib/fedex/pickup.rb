require 'fedex/credentials'
require 'fedex/request/pickup'

module Fedex
  class Pickup

    # In order to use Fedex rates API you must first apply for a developer(and later production keys),
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

    def pickup(options = {})
      options[:pickup] = true
      Request::Pickup.new(@credentials, options).process_request
    end


  end
end
