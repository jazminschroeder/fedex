require 'fedex/request/base'

module Fedex
  module Request
    class PickupAvailability < Base

      def initialize(credentials, options={})
        requires!(options, :country_code, :request_type, :carrier_code)
        @debug = ENV['DEBUG'] == 'true'

        @credentials = credentials
        
        @country_code  = options[:country_code]
        @postal_code   = options[:postal_code] if options[:postal_code]
        @state_code    = options[:state_code] if options[:state_code]
        @request_type  = options[:request_type]
        @carrier_code  = options[:carrier_code]
        @dispatch_date = options[:dispatch_date] if options[:dispatch_date]
      end

      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          success_response(api_response, response)
        else
          failure_response(api_response, response)
        end
      end

      private

      # Build xml Fedex Web Service request
      def build_xml
        ns = "http://fedex.com/ws/pickup/v#{service[:version]}"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.PickupAvailabilityRequest(:xmlns => ns) {
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_pickup_address(xml)
            add_other_pickup_details(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'disp', :version => Fedex::PICKUP_API_VERSION }
      end

      def add_pickup_address(xml)
        xml.PickupAddress{
          xml.PostalCode @postal_code if @postal_code
          xml.CountryCode @country_code
          xml.StateOrProvinceCode @state_code if @state_code
        }
      end

      def add_other_pickup_details(xml)
        xml.PickupRequestType @request_type
        xml.DispatchDate @dispatch_date if @dispatch_date
        xml.Carriers @carrier_code
      end

      # Callback used after a failed pickup response.
      def failure_response(api_response, response)
        error_message = if response[:pickup_availability_reply]
          [response[:pickup_availability_reply][:notifications]].flatten.first[:message]
        else
          "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
        end rescue $1
        raise RateError, error_message
      end

      # Callback used after a successful pickup response.
      def success_response(api_response, response)
        @response_details = response[:pickup_availability_reply]
      end

      # Successful request
      def success?(response)
        response[:pickup_availability_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:pickup_availability_reply][:highest_severity])
      end
    end
  end
end
