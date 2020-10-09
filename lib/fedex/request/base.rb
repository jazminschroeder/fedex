# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'fedex/helpers'
require 'fedex/rate'
require 'fedex/rates'

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
      PRODUCTION_URL = 'https://ws.fedex.com:443/xml/'

      # List of available Service Types
      SERVICE_TYPES = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY FEDEX_FREIGHT_PRIORITY FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY INTERNATIONAL_ECONOMY INTERNATIONAL_ECONOMY_FREIGHT INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY INTERNATIONAL_PRIORITY_FREIGHT PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT FEDEX_DISTANCE_DEFERRED FEDEX_NEXT_DAY_EARLY_MORNING FEDEX_NEXT_DAY_MID_MORNING FEDEX_NEXT_DAY_AFTERNOON FEDEX_NEXT_DAY_END_OF_DAY FEDEX_NEXT_DAY_FREIGHT).freeze

      # List of available Packaging Type
      PACKAGING_TYPES = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING).freeze

      # List of available DropOffTypes
      DROP_OFF_TYPES = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION).freeze

      # Clearance Brokerage Type
      CLEARANCE_BROKERAGE_TYPE = %w(BROKER_INCLUSIVE BROKER_INCLUSIVE_NON_RESIDENT_IMPORTER BROKER_SELECT BROKER_SELECT_NON_RESIDENT_IMPORTER BROKER_UNASSIGNED).freeze

      # Recipient Custom ID Type
      RECIPIENT_CUSTOM_ID_TYPE = %w(COMPANY INDIVIDUAL PASSPORT).freeze

      # List of available Payment Types
      PAYMENT_TYPE = %w(RECIPIENT SENDER THIRD_PARTY).freeze

      # List of available Carrier Codes
      CARRIER_CODES = %w(FDXC FDXE FDXG FDCC FXFR FXSP).freeze

      # List of available TIN (Tax Identification Number) types
      TIN_TYPES = %(BUSINESS_NATIONAL BUSINESS_STATE BUSINESS_UNION PERSONAL_NATIONAL PERSONAL_STATE).freeze

      # In order to use Fedex rates API you must first apply for a developer(and later production keys),
      # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
      # @param [String] key - Fedex web service key
      # @param [String] password - Fedex password
      # @param [String] account_number - Fedex account_number
      # @param [String] meter - Fedex meter number
      # @param [String] mode - [development/production]
      #
      # return a Fedex::Request::Base object
      def initialize(credentials, options = {})
        requires!(options, :shipper, :recipient, :packages)
        @credentials = credentials
        @shipper = options[:shipper]
        @recipient = options[:recipient]
        @packages = options[:packages]
        @service_type = options[:service_type]
        @customs_clearance_detail = options[:customs_clearance_detail]
        @origin = options[:origin]
        @debug = ENV['DEBUG'] == 'true'
        @shipping_options = options[:shipping_options] ||= {}
        @payment_options = options[:payment_options] ||= {}
        requires!(@payment_options, :type, :account_number, :name, :company, :phone_number, :country_code) unless @payment_options.empty?
        if options.key?(:mps)
          @mps = options[:mps]
          requires!(@mps, :package_count, :total_weight, :sequence_number)
          requires!(@mps, :master_tracking_id) if @mps.key?(:sequence_number) && @mps[:sequence_number].to_i >= 2
        else
          @mps = {}
        end
        # Expects hash with addr and port
        if options[:http_proxy]
          self.class.http_proxy options[:http_proxy][:host], options[:http_proxy][:port]
        end
      end

      # Sends post request to Fedex web service and parse the response.
      # Implemented by each subclass
      def process_request
        raise NotImplementedError, 'Override process_request in subclass'
      end

      private

      def add_standard_request_details(xml)
        add_web_authentication_detail(xml)
        add_client_detail(xml)
        add_version(xml)
      end

      # Add web authentication detail information(key and password) to xml request
      def add_web_authentication_detail(xml)
        xml.WebAuthenticationDetail  do
          xml.UserCredential  do
            xml.Key @credentials.key
            xml.Password @credentials.password
          end
        end
      end

      # Add Client Detail information(account_number and meter_number) to xml request
      def add_client_detail(xml)
        xml.ClientDetail  do
          xml.AccountNumber @credentials.account_number
          xml.MeterNumber @credentials.meter
          xml.Localization  do
            xml.LanguageCode 'en' # English
            xml.LocaleCode   'us' # United States
          end
        end
      end

      # Add Version to xml request, using the version identified in the subclass
      def add_version(xml)
        xml.Version  do
          xml.ServiceId service[:id]
          xml.Major     service[:version]
          xml.Intermediate 0
          xml.Minor 0
        end
      end

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment  do
          xml.DropoffType @shipping_options[:drop_off_type] ||= 'REGULAR_PICKUP'
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= 'YOUR_PACKAGING'
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance_detail
          xml.RateRequestTypes 'NONE'
          add_packages(xml)
        end
      end

      # Add shipper to xml request
      def add_shipper(xml)
        xml.Shipper  do
          if @shipper.key?(:tins)
            xml.Tins do
              xml.TinType @shipper[:tins][:tin_type]
              xml.Number @shipper[:tins][:number]
            end
          end
          xml.Contact  do
            xml.PersonName @shipper[:name]
            xml.CompanyName @shipper[:company]
            xml.PhoneNumber @shipper[:phone_number]
            xml.EMailAddress @shipper[:email_address]
          end
          xml.Address do
            Array(@shipper[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @shipper[:city]
            xml.StateOrProvinceCode @shipper[:state]
            xml.PostalCode @shipper[:postal_code]
            xml.CountryCode @shipper[:country_code]
          end
        end
      end

      # Add shipper to xml request
      def add_origin(xml)
        xml.Origin  do
          xml.Contact  do
            xml.PersonName @origin[:name]
            xml.CompanyName @origin[:company]
            xml.PhoneNumber @origin[:phone_number]
          end
          xml.Address do
            Array(@origin[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @origin[:city]
            xml.StateOrProvinceCode @origin[:state]
            xml.PostalCode @origin[:postal_code]
            xml.CountryCode @origin[:country_code]
          end
        end
      end

      # Add recipient to xml request
      def add_recipient(xml)
        xml.Recipient  do
          xml.Contact  do
            xml.PersonName @recipient[:name]
            xml.CompanyName @recipient[:company]
            xml.PhoneNumber @recipient[:phone_number]
          end
          xml.Address do
            Array(@recipient[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @recipient[:city]
            xml.StateOrProvinceCode @recipient[:state]
            xml.PostalCode @recipient[:postal_code]
            xml.CountryCode @recipient[:country_code]
            xml.Residential @recipient[:residential]
          end
        end
      end

      # Add shipping charges to xml request
      def add_shipping_charges_payment(xml)
        xml.ShippingChargesPayment  do
          xml.PaymentType @payment_options[:type] || 'SENDER'
          xml.Payor  do
            if service[:version].to_i >= Fedex::API_VERSION.to_i
              xml.ResponsibleParty do
                xml.AccountNumber @payment_options[:account_number] || @credentials.account_number
                xml.Contact do
                  xml.PersonName @payment_options[:name] || @shipper[:name]
                  xml.CompanyName @payment_options[:company] || @shipper[:company]
                  xml.PhoneNumber @payment_options[:phone_number] || @shipper[:phone_number]
                end
              end
            else
              xml.AccountNumber @payment_options[:account_number] || @credentials.account_number
              xml.CountryCode @payment_options[:country_code] || @shipper[:country_code]
            end
          end
        end
      end

      def add_shipment_special_service_type(xml)
        return unless @shipping_options[:special_services_requested] && @shipping_options[:special_services_requested].fetch(:shipment_special_service_type, nil)

        xml.SpecialServicesRequested do
          xml.SpecialServiceTypes @shipping_options[:special_services_requested][:shipment_special_service_type]
        end
      end

      # Add Master Tracking Id (for MPS Shipping Labels, this is required when requesting labels 2 through n)
      def add_master_tracking_id(xml)
        if @mps.key? :master_tracking_id
          xml.MasterTrackingId  do
            xml.TrackingIdType @mps[:master_tracking_id][:tracking_id_type]
            xml.TrackingNumber @mps[:master_tracking_id][:tracking_number]
          end
        end
      end

      # Add packages to xml request
      def add_packages(xml)
        add_master_tracking_id(xml) if @mps.key? :master_tracking_id
        package_count = @packages.size
        if @mps.key? :package_count
          xml.PackageCount @mps[:package_count]
        else
          xml.PackageCount package_count
        end
        @packages.each do |package|
          xml.RequestedPackageLineItems  do
            if @mps.key? :sequence_number
              xml.SequenceNumber @mps[:sequence_number]
            else
              xml.GroupPackageCount 1
            end
            if package[:insured_value]
              xml.InsuredValue  do
                xml.Currency package[:insured_value][:currency]
                xml.Amount package[:insured_value][:amount]
              end
            end
            xml.Weight  do
              xml.Units package[:weight][:units]
              xml.Value package[:weight][:value]
            end
            if package[:dimensions]
              xml.Dimensions  do
                xml.Length package[:dimensions][:length]
                xml.Width package[:dimensions][:width]
                xml.Height package[:dimensions][:height]
                xml.Units package[:dimensions][:units]
              end
            end
            add_customer_references(xml, package)
            if package[:special_services_requested]
              xml.SpecialServicesRequested  do
                if package[:special_services_requested][:special_service_types]
                  if package[:special_services_requested][:special_service_types].is_a? Array
                    package[:special_services_requested][:special_service_types].each do |type|
                      xml.SpecialServiceTypes type
                    end
                  else
                    xml.SpecialServiceTypes package[:special_services_requested][:special_service_types]
                  end
                end
                # Handle COD Options
                if package[:special_services_requested][:cod_detail]
                  xml.CodDetail  do
                    xml.CodCollectionAmount  do
                      xml.Currency package[:special_services_requested][:cod_detail][:cod_collection_amount][:currency]
                      xml.Amount package[:special_services_requested][:cod_detail][:cod_collection_amount][:amount]
                    end
                    if package[:special_services_requested][:cod_detail][:add_transportation_charges]
                      xml.AddTransportationCharges package[:special_services_requested][:cod_detail][:add_transportation_charges]
                    end
                    xml.CollectionType package[:special_services_requested][:cod_detail][:collection_type]
                    xml.CodRecipient do
                      add_shipper(xml)
                    end
                    if package[:special_services_requested][:cod_detail][:reference_indicator]
                      xml.ReferenceIndicator package[:special_services_requested][:cod_detail][:reference_indicator]
                    end
                  end
                end
                # DangerousGoodsDetail goes here
                if package[:special_services_requested][:dry_ice_weight]
                  xml.DryIceWeight  do
                    xml.Units package[:special_services_requested][:dry_ice_weight][:units]
                    xml.Value package[:special_services_requested][:dry_ice_weight][:value]
                  end
                end
                if package[:special_services_requested][:signature_option_detail]
                  xml.SignatureOptionDetail  do
                    xml.OptionType package[:special_services_requested][:signature_option_detail][:signature_option_type]
                  end
                end
                if package[:special_services_requested][:priority_alert_detail]
                  xml.PriorityAlertDetail package[:special_services_requested][:priority_alert_detail]
                end
              end
            end
          end
        end
      end

      def add_customer_references(xml, package)
        # customer_refrences is a legacy misspelling
        if refs = package[:customer_references] || package[:customer_refrences]
          refs.each do |ref|
            xml.CustomerReferences  do
              if ref.is_a?(Hash)
                # :type can specify custom type:
                #
                # BILL_OF_LADING, CUSTOMER_REFERENCE, DEPARTMENT_NUMBER,
                # ELECTRONIC_PRODUCT_CODE, INTRACOUNTRY_REGULATORY_REFERENCE,
                # INVOICE_NUMBER, P_O_NUMBER, RMA_ASSOCIATION,
                # SHIPMENT_INTEGRITY, STORE_NUMBER
                xml.CustomerReferenceType ref[:type]
                xml.Value                 ref[:value]
              else
                xml.CustomerReferenceType 'CUSTOMER_REFERENCE'
                xml.Value                 ref
              end
            end
          end
        end
      end

      # Add customs clearance(for international shipments)
      def add_customs_clearance(xml)
        xml.CustomsClearanceDetail  do
          hash_to_xml(xml, @customs_clearance_detail)
        end
      end

      # Fedex Web Service Api
      def api_url
        @credentials.mode == 'production' ? PRODUCTION_URL : TEST_URL
      end

      # Build xml Fedex Web Service request
      # Implemented by each subclass
      def build_xml
        raise NotImplementedError, 'Override build_xml in subclass'
      end

      # Build xml nodes dynamically from the hash keys and values
      def hash_to_xml(xml, hash)
        hash.each do |key, value|
          key_s_down = key.to_s.downcase
          element = if key_s_down.match?(/^commodities_\d{1,}$/)
                      'Commodities'
                    elsif key_s_down.match?(/^masked_data_\d{1,}$/)
                      'MaskedData'
                    else
                      camelize(key)
                    end
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
        sanitize_response_keys(response.parsed_response)
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
        if @recipient[:residential].to_s =~ /true/i && @service_type =~ /GROUND/i && @recipient[:country_code] =~ /US/i
          'GROUND_HOME_DELIVERY'
        else
          @service_type
        end
      end

      # Successful request
      def success?(response)
        (!response[:rate_reply].nil? && %w{SUCCESS WARNING NOTE}.include?(response[:rate_reply][:highest_severity]))
      end
    end
  end
end
