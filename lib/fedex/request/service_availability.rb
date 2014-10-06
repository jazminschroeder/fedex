require 'fedex/request/base'

module Fedex
  module Request
    class ServiceAvailability < Base
      def initialize(credentials, options={})
        requires!(options, :origin, :destination, :ship_date, :carrier_code)

        @credentials  = credentials
        @origin       = options[:origin]
        @destination  = options[:destination]
        @ship_date    = options[:ship_date]
        @carrier_code = options[:carrier_code]
      end

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

      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.ServiceAvailabilityRequest(:xmlns => "http://fedex.com/ws/packagemovementinformationservice/v#{service[:version]}"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_origin(xml)
            add_destination(xml)
            add_other_details(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def add_origin(xml)
        xml.Origin{
          xml.PostalCode  @origin[:postal_code]
          xml.CountryCode @origin[:country_code]
        }
      end

      def add_destination(xml)
        xml.Destination{
          xml.PostalCode  @destination[:postal_code]
          xml.CountryCode @destination[:country_code]
        }
      end

      def add_other_details(xml)
        xml.ShipDate @ship_date
        xml.CarrierCode @carrier_code
      end

      # Callback used after a failed shipment response.
      def failure_response(api_response, response)
        error_message = if response[:service_availability_reply]
          [response[:service_availability_reply][:notifications]].flatten.first[:message]
        else
          "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
        end rescue $1
        raise RateError, error_message
      end

      # Callback used after a successful shipment response.
      def success_response(api_response, response)
        @response_details = response[:service_availability_reply]
      end      

      def service
        { :id => 'pmis', :version => Fedex::SERVICE_AVAILABILITY_API_VERSION }
      end

      # Successful request
      def success?(response)
        response[:service_availability_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:service_availability_reply][:highest_severity])
      end
    end
  end
end