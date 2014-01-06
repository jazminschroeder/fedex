require 'fedex/request/base'

module Fedex
  module Request
    class PendingShipment < Shipment
      attr_reader :response_details

      def initialize(credentials, options={})
        super(credentials, options)
        @special_service_details= options[:special_service_details]
      end

      # Sends post request to Fedex web service and parse the response.
      # A label file is created with the label at the specified location.
      # The parsed Fedex response is available in #response_details
      # e.g. response_details[:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number]
      def process_request
        api_response = self.class.post api_url, :body => build_xml

        puts api_response if @debug
        response = parse_response(api_response)
        if success?(response)
          success_response(api_response, response)
        else
          failure_response(api_response, response)
        end
      end

      # Callback used after a failed shipment response.
      def failure_response(api_response, response)
        error_message = if response[:create_pending_shipment_reply]
                          [response[:create_pending_shipment_reply][:notifications]].flatten.first[:message]
                        else
                          "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
                        end rescue $1
        raise RateError, error_message
      end

      # Callback used after a successful shipment response.
      def success_response(api_response, response)
        @response_details = response[:create_pending_shipment_reply]
        Fedex::PendingShipmentLabel.new @response_details
      end

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
          add_special_services_for_return(xml)
          add_customs_clearance(xml) if @customs_clearance
          add_custom_components(xml)
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      def add_special_services_for_return(xml)
        xml.SpecialServicesRequested{
          xml.SpecialServiceTypes 'RETURN_SHIPMENT'
          xml.SpecialServiceTypes 'PENDING_SHIPMENT'
          xml.ReturnShipmentDetail{
            xml.ReturnType 'PENDING'
            xml.ReturnEMailDetail{
              xml.MerchantPhoneNumber @special_service_details[:special_services_requested][:return_shipment_detail][:return_email_detail][:merchant_phone_number]
            }
          }
          xml.PendingShipmentDetail{
            xml.Type "EMAIL"
            xml.ExpirationDate @special_service_details[:special_services_requested][:pending_shipment_detail][:expiration_date]
            xml.EmailLabelDetail{
              xml.NotificationEMailAddress @special_service_details[:special_services_requested][:pending_shipment_detail][:email_label_detail][:notification_email_address]
              xml.NotificationMessage @special_service_details[:special_services_requested][:pending_shipment_detail][:email_label_detail][:notification_message]
            }
          }

        }

      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.CreatePendingShipmentRequest(:xmlns => "http://fedex.com/ws/ship/v12"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_shipment(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'ship', :version => 12 }
      end

      def success?(response)
        response[:create_pending_shipment_reply] &&
            %w{SUCCESS WARNING NOTE}.include?(response[:create_pending_shipment_reply][:highest_severity])
      end

    end
  end
end
