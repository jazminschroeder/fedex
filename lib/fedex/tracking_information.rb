require 'fedex/tracking_information/event'

module Fedex
  class TrackingInformation
    PACKAGE_IDENTIFIER_TYPES = %w{
      BILL_OF_LADING
      COD_RETURN_TRACKING_NUMBER
      CUSTOMER_AUTHORIZATION_NUMBER
      CUSTOMER_REFERENCE
      DEPARTMENT
      FREE_FORM_REFERENCE
      GROUND_INTERNATIONAL
      GROUND_SHIPMENT_ID
      GROUP_MPS
      INVOICE
      JOB_GLOBAL_TRACKING_NUMBER
      ORDER_GLOBAL_TRACKING_NUMBER
      ORDER_TO_PAY_NUMBER
      PARTNER_CARRIER_NUMBER
      PART_NUMBER
      PURCHASE_ORDER
      RETURN_MATERIALS_AUTHORIZATION
      RETURNED_TO_SHIPPER_TRACKING_NUMBER
      TRACKING_CONTROL_NUMBER
      TRACKING_NUMBER_OR_DOORTAG
      TRANSPORTATION_CONTROL_NUMBER
      SHIPPER_REFERENCE
      STANDARD_MPS
    }

    attr_reader :tracking_number, :signature_name, :service_type, :status,
                :delivery_at, :events

    def initialize(details = {})
      @details = details

      @tracking_number = details[:tracking_number]
      @signature_name  = details[:delivery_signature_name]
      @service_type    = details[:service_type]
      @status          = details[:status_description]
      if details.has_key?(:actual_delivery_timestamp)
        @delivery_at = Time.parse(details[:actual_delivery_timestamp])
      end

      # Wrap events in an array if there is only one event.
      details[:events] = [details[:events]] if details[:events].is_a?(Hash)

      @events = details[:events].map do |event_details|
        Event.new(event_details)
      end
    end
  end
end