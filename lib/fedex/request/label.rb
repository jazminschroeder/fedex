require 'fedex/request/base'
require 'fileutils'

module Fedex
  module Request
    class Label < Base
      attr_reader :response_details

      def initialize(credentials, options={})
        super(credentials, options)
        requires!(options, :filename)
        @filename = options[:filename]
        @label_specification = {
          label_format_type: 'COMMON2D',
          image_type: 'PDF',
          label_stock_type: 'PAPER_LETTER'
        }
        @label_specification.merge!(options[:label_specification]) if options[:label_specification]
      end

      # Sends post request to Fedex web service and parse the response.
      # A label file is created with the label at the specified location.
      # The parse Fedex response is available in #response_details
      # e.g. response_details[:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number]
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          @response_details = response[:process_shipment_reply]
          create_label_file
        else
          error_message = if response[:process_shipment_reply]
            [response[:process_shipment_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.ShipTimestamp Time.now.utc.iso8601(2)
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance
          add_label_specification(xml)
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      # Add the label specification
      def add_label_specification(xml)
        xml.LabelSpecification {
          hash_to_xml(xml, @label_specification)
        }
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.ProcessShipmentRequest(:xmlns => "http://fedex.com/ws/ship/v10"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_shipment(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def create_label_file
        [
          @response_details[:completed_shipment_detail][:completed_package_details][:label][:parts]
        ].flatten.each do |part|
          if image = (Base64.decode64(part[:image]) if part[:image])
            FileUtils.mkdir_p File.dirname(@filename)
            File.open(@filename, 'w') do |file|
              file.write image
            end
          end
        end
      end

      def service_id
        'ship'
      end

      # Successful request
      def success?(response)
        response[:process_shipment_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:process_shipment_reply][:highest_severity])
      end

    end
  end
end
