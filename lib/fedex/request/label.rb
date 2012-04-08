require 'fedex/request/base'
require 'fedex/label'

module Fedex
  module Request
    class Label < Base
      def initialize(credentials, options={})
        super(credentials, options)
        requires!(options, :filename)
        @filename = options[:filename]
      end

      # Sends post request to Fedex web service and parse the response.
      # A Fedex::Label object is created if the response is successful and
      # a PDF file is created with the label at the specified location.
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          label_details = response[:process_shipment_reply][:completed_shipment_detail][:completed_package_details][:label]

          create_pdf(label_details)
          Fedex::Label.new(label_details)
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
          xml.LabelSpecification {
            xml.LabelFormatType "COMMON2D"
            xml.ImageType "PDF"
          }
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
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

      def create_pdf(label_details)
        [label_details[:parts]].flatten.each do |part|
          if image = (Base64.decode64(part[:image]) if part[:image])
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