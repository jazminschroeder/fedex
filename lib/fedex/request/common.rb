require 'httparty'
require 'nokogiri'
require 'fedex/helpers'

module Fedex
  module Request
    class Common
      include Helpers
      include HTTParty
      format :xml

      # If true the rate method will return the complete response from the Fedex Web Service
      attr_accessor :debug
      # Fedex Text URL
      TEST_URL = "https://wsbeta.fedex.com:443/xml/"

      # Fedex Production URL
      PRODUCTION_URL = "https://ws.fedex.com:443/xml/"

      def initialize(credentials, options={})
        @credentials = credentials
        @debug = ENV['DEBUG'] == 'true'

        # Expects hash with addr and port
        if options[:http_proxy]
          self.class.http_proxy options[:http_proxy][:host], options[:http_proxy][:port]
        end
      end


      # Sends post request to Fedex web service and parse the response.
      # Implemented by each subclass
      def process_request
        raise NotImplementedError, "Override process_request in subclass"
      end

      private
      # Add web authentication detail information(key and password) to xml request
      def add_web_authentication_detail(xml)
        xml.WebAuthenticationDetail{
          xml.UserCredential{
            xml.Key @credentials.key
            xml.Password @credentials.password
          }
        }
      end

      # Add Client Detail information(account_number and meter_number) to xml request
      def add_client_detail(xml)
        xml.ClientDetail{
          xml.AccountNumber @credentials.account_number
          xml.MeterNumber @credentials.meter
          xml.Localization{
            xml.LanguageCode 'en' # English
            xml.LocaleCode   'us' # United States
          }
        }
      end

      # Add Version to xml request, using the version identified in the subclass
      def add_version(xml)
        xml.Version{
          xml.ServiceId service[:id]
          xml.Major     service[:version]
          xml.Intermediate 0
          xml.Minor 0
        }
      end

      # Fedex Web Service Api
      def api_url
        @credentials.mode == "production" ? PRODUCTION_URL : TEST_URL
      end

      # Build xml Fedex Web Service request
      # Implemented by each subclass
      def build_xml
        raise NotImplementedError, "Override build_xml in subclass"
      end

      # Build xml nodes dynamically from the hash keys and values
      def hash_to_xml(xml, hash)
        hash.each do |key, value|
          element = camelize(key)
          if value.is_a?(Hash)
            xml.send element do |x|
              hash_to_xml(x, value)
            end
          elsif value.is_a?(Array)
            value.each do |v|
              xml.send element do |x|
                hash_to_xml(x, v)
              end
            end
          else
            xml.send element, value
          end
        end
      end

      # Parse response, convert keys to underscore symbols
      def parse_response(response)
        response = sanitize_response_keys(response)
      end

      # Recursively sanitizes the response object by cleaning up any hash keys.
      def sanitize_response_keys(response)
        if response.is_a?(Hash)
          response.inject({}) { |result, (key, value)| result[underscorize(key).to_sym] = sanitize_response_keys(value); result }
        elsif response.is_a?(Array)
          response.collect { |result| sanitize_response_keys(result) }
        else
          response
        end
      end

      def service
        raise NotImplementedError,
          "Override service in subclass: {:id => 'service', :version => 1}"
      end

      # Use GROUND_HOME_DELIVERY for shipments going to a residential address within the US.
      def service_type
        if @recipient[:residential].to_s =~ /true/i and @service_type =~ /GROUND/i and @recipient[:country_code] =~ /US/i
          "GROUND_HOME_DELIVERY"
        else
          @service_type
        end
      end

      # Successful request
      def success?(response)
        (!response[:rate_reply].nil? and %w{SUCCESS WARNING NOTE}.include? response[:rate_reply][:highest_severity])
      end

    end
  end
end
