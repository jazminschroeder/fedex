require 'fedex/request/base'

module Fedex
  module Request
    class Pickup < Base
      attr_reader :response_details

      def initialize(credentials, options={})
        super
        requires!(options, :service_type)
      end

      # Sends post request to Fedex web service and parse the response.
      # The parsed Fedex response is available in #response_details
      def process_request
        xml = build_xml
        puts xml if @debug
        api_response = self.class.post api_url, :body => xml
        puts api_response if @debug
        response = parse_response(api_response)
        if success?(response)
          success_response(api_response, response)
        else
          failure_response(api_response, response)
        end
      end

      private

      # Add information for pickup request
      def add_requested_pickup(xml)
        xml.RequestedPickup{
          xml.ShipTimestamp @shipping_options[:ship_timestamp] ||= Time.now.utc.iso8601(2)
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_total_weight(xml) if @mps.has_key? :total_weight
          add_shipper(xml)
          add_recipient(xml)
          add_origin(xml) if @origin
          add_shipping_charges_payment(xml)
          add_special_services(xml) if @shipping_options[:return_reason]
          add_customs_clearance(xml) if @customs_clearance_detail
          add_custom_components(xml)
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      # Callback used after a failed shipment response.
      def failure_response(api_response, response)
       # error_message = if response[:process_shipment_reply]
       #   [response[:process_shipment_reply][:notifications]].flatten.first[:message]
       # else
       #   "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
       # end rescue $1
       # raise RateError, error_message
      end

      # Callback used after a successful shipment response.
      def success_response(api_response, response)
      #  @response_details = response[:process_shipment_reply]
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.ProcessPickupRequest(:xmlns => "http://fedex.com/ws/pickup/v#{service[:version]}"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_pickup(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'ship', :version => Fedex::API_VERSION }
      end

      # Successful request
      def success?(response)
        #response[:process_shipment_reply] &&
        #  %w{SUCCESS WARNING NOTE}.include?(response[:process_shipment_reply][:highest_severity])
      end

    end
  end
end
