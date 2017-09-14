require 'httparty'
require 'nokogiri'
require 'fedex/helpers'
require 'fedex/rate'

module Fedex
  module Request
    class Base
      include Helpers
      include HTTParty
      format :xml
      # If true the rate method will return the complete response from the Fedex Web Service
      attr_accessor :debug
      # Fedex Text URL
      TEST_URL = 'https://wsbeta.fedex.com:443/xml/'

      # Fedex Production URL
      PRODUCTION_URL = "https://gateway.fedex.com:443/xml/"

      # List of available Service Types
      SERVICE_TYPES = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY FEDEX_FREIGHT_PRIORITY FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY INTERNATIONAL_ECONOMY INTERNATIONAL_ECONOMY_FREIGHT INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY INTERNATIONAL_PRIORITY_FREIGHT PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT)

      # List of available Packaging Type
      PACKAGING_TYPES = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING)

      # List of available DropOffTypes
      DROP_OFF_TYPES = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION)

      # Clearance Brokerage Type
      CLEARANCE_BROKERAGE_TYPE = %w(BROKER_INCLUSIVE BROKER_INCLUSIVE_NON_RESIDENT_IMPORTER BROKER_SELECT BROKER_SELECT_NON_RESIDENT_IMPORTER BROKER_UNASSIGNED)

      # Recipient Custom ID Type
      RECIPIENT_CUSTOM_ID_TYPE = %w(COMPANY INDIVIDUAL PASSPORT)

      # In order to use Fedex rates API you must first apply for a developer(and later production keys),
      # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
      # @param [String] key - Fedex web service key
      # @param [String] password - Fedex password
      # @param [String] account_number - Fedex account_number
      # @param [String] meter - Fedex meter number
      # @param [String] mode - [development/production]
      #
      # return a Fedex::Request::Base object
      def initialize(credentials, options={})
        requires!(options, :shipper, :recipient, :packages, :service_type)
        @credentials = credentials
        @shipper, @recipient, @packages, @service_type, @customs_clearance, @debug = options[:shipper], options[:recipient], options[:packages], options[:service_type], options[:customs_clearance], options[:debug]
        @debug = ENV['DEBUG'] == 'true'
        @shipping_options =  options[:shipping_options] ||={}
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

      # Add Version to xml request, using the latest version V10 Sept/2011
      def add_version(xml)
        xml.Version{
          xml.ServiceId service[:id]
          xml.Major     service[:version]
          xml.Intermediate 0
          xml.Minor 0
        }
      end

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      # Add shipper to xml request
      def add_shipper(xml)
        xml.Shipper{
          xml.Contact{
            xml.PersonName @shipper[:name]
            xml.CompanyName @shipper[:company]
            xml.PhoneNumber @shipper[:phone_number]
          }
          xml.Address {
            Array(@shipper[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @shipper[:city]
            xml.StateOrProvinceCode @shipper[:state]
            xml.PostalCode @shipper[:postal_code]
            xml.CountryCode @shipper[:country_code]
          }
        }
      end

      # Add recipient to xml request
      def add_recipient(xml)
        xml.Recipient{
          xml.Contact{
            xml.PersonName @recipient[:name]
            xml.CompanyName @recipient[:company]
            xml.PhoneNumber @recipient[:phone_number]
          }
          xml.Address {
            Array(@recipient[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @recipient[:city]
            xml.StateOrProvinceCode @recipient[:state]
            xml.PostalCode @recipient[:postal_code]
            xml.CountryCode @recipient[:country_code]
            xml.Residential @recipient[:residential]
          }
        }
      end

      # Add shipping charges to xml request
      def add_shipping_charges_payment(xml)
        xml.ShippingChargesPayment{
          xml.PaymentType @shipping_options[:payment_type] ||= "SENDER"
          xml.Payor{
            xml.AccountNumber (@shipping_options[:payor] && @shipping_options[:payor][:account_number]) || @credentials.account_number
            xml.CountryCode @shipper[:country_code]
          }
        }
      end

      # Add packages to xml request
      def add_packages(xml)
        package_count = @packages.size
        xml.PackageCount package_count
        @packages.each do |package|
          xml.RequestedPackageLineItems{
            xml.GroupPackageCount 1
            xml.Weight{
              xml.Units package[:weight][:units]
              xml.Value package[:weight][:value]
            }
            if package[:dimensions]
              xml.Dimensions{
                xml.Length package[:dimensions][:length]
                xml.Width package[:dimensions][:width]
                xml.Height package[:dimensions][:height]
                xml.Units package[:dimensions][:units]
              }
            end
            if package[:customer_refrences]
              xml.CustomerReferences{
              package[:customer_refrences].each do |value|
                 xml.CustomerReferenceType 'CUSTOMER_REFERENCE'
                 xml.Value                 value
              end
              }
            end
            if package[:special_services_requested] && package[:special_services_requested][:special_service_types]
              xml.SpecialServicesRequested{
                if package[:special_services_requested][:special_service_types].is_a? Array
                  package[:special_services_requested][:special_service_types].each do |type|
                    xml.SpecialServiceTypes type
                  end
                else
                  xml.SpecialServiceTypes package[:special_services_requested][:special_service_types]
                end
                # Handle COD Options
                if package[:special_services_requested][:cod_detail]
                  xml.CodDetail{
                    xml.CodCollectionAmount{
                      xml.Currency package[:special_services_requested][:cod_detail][:cod_collection_amount][:currency]
                      xml.Amount package[:special_services_requested][:cod_detail][:cod_collection_amount][:amount]
                    }
                    if package[:special_services_requested][:cod_detail][:add_transportation_charges]
                      xml.AddTransportationCharges package[:special_services_requested][:cod_detail][:add_transportation_charges]
                    end
                    xml.CollectionType package[:special_services_requested][:cod_detail][:collection_type]
                    xml.CodRecipient {
                      add_shipper(xml)
                    }
                    if package[:special_services_requested][:cod_detail][:reference_indicator]
                      xml.ReferenceIndicator package[:special_services_requested][:cod_detail][:reference_indicator]
                    end
                  }
                end
                # DangerousGoodsDetail goes here
                if package[:special_services_requested][:dry_ice_weight]
                  xml.DryIceWeight{
                    xml.Units package[:special_services_requested][:dry_ice_weight][:units]
                    xml.Value package[:special_services_requested][:dry_ice_weight][:value]
                  }
                end
                if package[:special_services_requested][:signature_option_detail]
                  xml.SignatureOptionDetail{
                    xml.OptionType package[:special_services_requested][:signature_option_detail][:signature_option_type]
                  }
                end
                if package[:special_services_requested][:priority_alert_detail]
                  xml.PriorityAlertDetail package[:special_services_requested][:priority_alert_detail]
                end
              }
            end
          }
        end
      end

      # Add customs clearance(for international shipments)
      def add_customs_clearance(xml)
        xml.CustomsClearanceDetail{
          hash_to_xml(xml, @customs_clearance)
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
        response = sanitize_response_keys(response.parsed_response)
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
