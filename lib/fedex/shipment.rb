require 'fedex/credentials'
require 'fedex/request/label'
require 'fedex/request/rate'
require 'fedex/request/tracking_information'
require 'fedex/request/address'
require 'fedex/request/document'
require 'fedex/request/delete'
require 'fedex/request/ground_close'
require 'fedex/request/pickup'
require 'fedex/request/pickup_availability'
require 'fedex/request/service_availability'

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
    # @param [Array] packages, An array including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    # @param [String] filename, A location where the label will be saved
    # @param [Hash] label_specification, A hash containing the label printer settings
    def label(options = {})
      Request::Label.new(@credentials, options).process_request
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An array including a hash for each package being shipped
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
    # @param [Array] packages, An array including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    def ship(options = {})
      Request::Shipment.new(@credentials, options).process_request
    end

    # @param [String] carrier_code, A valid fedex carrier code, to view a complete list of carrier codes Fedex::Shipment::CARRIER_CODES
    # @param [Hash] packages, A hash containing the number of packages and their total weight
    # @param [DateTime] ready_timestamp, A timestamp that indicates what day and time the package will be available for pickup
    # @param [Time] close_time, The latest time that the business will be open to accept a pickup
    # @param [Hash] pickup_location, A hash containing the pickup location information
    def pickup(options = {})
      Request::Pickup.new(@credentials, options).process_request
    end

    # @param [Hash] package_id, A string with the requested tracking number
    # @param [Hash] package_type, A string identifitying the type of tracking number used. Full list Fedex::Track::PACKAGE_IDENTIFIER_TYPES
    def track(options = {})
      Request::TrackingInformation.new(@credentials, options).process_request
    end

    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An array including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    # @param [Hash] customs_clearance, A hash containing customs clearance specification
    # @param [Hash] shipping_document, A hash containing shipping document specification
    # @param [Array] filenames, A location where the label and shipment documents will be saved
    def document(options = {})
      Request::Document.new(@credentials, options).process_request
    end

    # @param [Hash] package_id, A string with the tracking number to delete
    def delete(options = {})
      Request::Delete.new(@credentials, options).process_request
    end

    # @param [Date] up_to_time, A time up to which shipments are to be closed
    # @param [String] filename, A location where the manifest (text file) will be saved
    def ground_close(options = {})
      Request::GroundClose.new(@credentials, options).process_request
    end
    # @param [String] country_code, A string containing country code
    # @param [String] state_code, A string containing state code
    # @param [String] postal_code, A string containing postal code
    # @param [String] carrier_code, A string containing carrier code
    # @param [String] request_type, A string with request type
    # @param [String] dispatch_date, A string with dispatch date in YYYY-MM-DD format
    def pickup_availability(options = {})
      Request::PickupAvailability.new(@credentials, options).process_request
    end

    # param [Hash] origin, A hash containing origin information
    # param [Hash] destination, A hash containing destination information
    # param [date] ship_date, A string containing ship date in YYYY-MM-DD format
    # param [String] carrier_code, A string containing carrier code
    def service_availability(options = {})
      Request::ServiceAvailability.new(@credentials, options).process_request
    end

  end
end
