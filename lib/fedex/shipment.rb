require 'fedex/credentials'
require 'fedex/request/label'
require 'fedex/request/rate'
require 'fedex/request/tracking_information'
require 'fedex/request/address'

module Fedex
  class Shipment

    # In order to use Fedex rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - Fedex web service key
    # @param [String] password - Fedex password
    # @param [String] account_number - Fedex account_number
    # @param [String] meter - Fedex meter number
    # @param [String] mode - [development/production]
    #
    # return a Fedex::Shipment object
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    # @param [String] filename, A location where the label will be saved
    # @param [Hash] label_specification, A hash containing the label printer settings
    def label(options = {})
      Request::Label.new(@credentials, options).process_request
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    def rate(options = {})
      Request::Rate.new(@credentials, options).process_request
    end

    # @param [Hash] address, A hash containing the address information
    def validate_address(options = {})
      Request::Address.new(@credentials, options).process_request
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    def ship(options = {})
      Request::Shipment.new(@credentials, options).process_request
    end

    # @param [Hash] package_id, A string with the requested tracking number
    # @param [Hash] package_type, A string identifitying the type of tracking number used. Full list Fedex::Track::PACKAGE_IDENTIFIER_TYPES
    def track(options = {})
      Request::TrackingInformation.new(@credentials, options).process_request
    end

  end
end
