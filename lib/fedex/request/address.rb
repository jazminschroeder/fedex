require 'fedex/request/base'
require 'fedex/address'
require 'fileutils'

module Fedex
  module Request
    class Address < Base
      def initialize(credentials, options={})
        requires!(options, :address)
        @credentials = credentials
        @address     = options[:address]
      end

      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          options = response[:address_validation_reply][:address_results][:proposed_address_details]

          Fedex::Address.new(options)
        else
          error_message = if response[:address_validation_reply]
            [response[:address_validation_reply][:notifications]].flatten.first[:message]
          else
            api_response["Fault"]["detail"]["fault"]["reason"]
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.AddressValidationRequest(:xmlns => "http://fedex.com/ws/addressvalidation/v2"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_request_timestamp(xml)
            add_address_validation_options(xml)
            add_address_to_validate(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def add_request_timestamp(xml)
        timestamp = Time.now

        # Calculate current timezone offset manually.
        # Ruby <= 1.9.2 does not support this in Time#strftime
        #
        utc_offest = "#{timestamp.gmt_offset < 0 ? "-" : "+"}%02d:%02d" %
                     (timestamp.gmt_offset / 60).abs.divmod(60)
        timestamp  = timestamp.strftime("%Y-%m-%dT%H:%M:%S") + utc_offest

        xml.RequestTimestamp timestamp
      end

      def add_address_validation_options(xml)
        xml.Options{
          xml.CheckResidentialStatus true
        }
      end

      def add_address_to_validate(xml)
        xml.AddressesToValidate{
          xml.Address{
            xml.StreetLines         @address[:street]
            xml.City                @address[:city]
            xml.StateOrProvinceCode @address[:state]
            xml.PostalCode          @address[:postal_code]
            xml.CountryCode         @address[:country]
          }
        }
      end

      def service
        { :id => 'aval', :version => 2 }
      end

      # Successful request
      def success?(response)
        response[:address_validation_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:address_validation_reply][:highest_severity])
      end

    end
  end
end