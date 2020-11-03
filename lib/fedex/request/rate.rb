# frozen_string_literal: true

require 'fedex/request/base'

module Fedex
  module Request
    class Rate < Base
      # Sends post request to Fedex web service and parse the response, a Rate object is created if the response is successful
      def process_request
        @request_xml = build_xml
        @response_xml = self.class.post(api_url, body: @request_xml)
        puts @response_xml if @debug
        response = parse_response(@response_xml)
        if success?(response)
          rate_reply_details = response[:rate_reply][:rate_reply_details] || []
          rate_reply_details = [rate_reply_details] if rate_reply_details.is_a?(Hash)

          rates = rate_reply_details.map do |rate_reply|
            rate_details = [rate_reply[:rated_shipment_details]].flatten.first[:shipment_rate_detail]
            rate_details[:service_type] = rate_reply[:service_type]
            rate_details[:transit_time] = rate_reply[:transit_time]
            rate_details[:special_rating_applied] = rate_details[:special_rating_applied]
            Fedex::Rate.new(rate_details)
          end

          Fedex::Rates.new(rates, request_xml: @request_xml, response_xml: @response_xml)
        else
          error_message = begin
                            if response[:rate_reply]
                              [response[:rate_reply][:notifications]].flatten.first[:message]
                            else
                              "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
                            end
                          rescue StandardError
                            $1
                          end
          raise RateError, error_message
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment  do
          xml.DropoffType @shipping_options[:drop_off_type] ||= 'REGULAR_PICKUP'
          xml.ServiceType service_type if service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= 'YOUR_PACKAGING'
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_shipment_special_service_type(xml)
          add_customs_clearance(xml) if @customs_clearance_detail
          xml.RateRequestTypes 'NONE'
          add_packages(xml)
        end
      end

      # Add transite time options
      def add_transit_time(xml)
        xml.ReturnTransitAndCommit true
      end

      # Build xml Fedex Web Service request
      def build_xml
        ns = "http://fedex.com/ws/rate/v#{service[:version]}"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.RateRequest(xmlns: ns)  do
            add_standard_request_details(xml)

            add_transit_time(xml)
            add_requested_shipment(xml)
          end
        end
        builder.doc.root.to_xml
      end

      def service
        { id: 'crs', version: Fedex::API_VERSION }
      end

      # Successful request
      def success?(response)
        response[:rate_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:rate_reply][:highest_severity])
      end
    end
  end
end
