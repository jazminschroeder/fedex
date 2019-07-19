# frozen_string_literal: true

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
    }.freeze

    attr_reader :tracking_number, :signature_name, :service_type, :status, :status_code, :delivery_at, :events, :unique_tracking_number, :details, :other_identifiers

    def initialize(details = {})
      @details = details

      @tracking_number        = details[:tracking_number]
      @unique_tracking_number = details[:tracking_number_unique_identifier]
      @signature_name         = details[:delivery_signature_name]
      @service_type           = details[:service_type]
      @status                 = details[:status_description]
      @status_code            = details[:status_code]
      @other_identifiers      = details[:other_identifiers]

      if details.key?(:actual_delivery_timestamp)
        @delivery_at = Time.parse(details[:actual_delivery_timestamp])
      end

      @events = [details[:events]].flatten.compact.map do |event_details|
        Event.new(event_details)
      end
    end
  end
end
