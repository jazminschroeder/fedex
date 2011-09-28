require 'httparty'
require 'nokogiri'
module Fedex
  class Shipment
    include HTTParty
    format :xml
    # Fedex Text URL
    TEST_URL = "https://gatewaybeta.fedex.com:443/xml/"
    
    # Fedex Production URL
    PRODUCTION_URL = "https://gateway.fedex.com:443/xml/"
    
    # Fedex Version number for the Fedex service used
    VERSION = 10
    
    # List of available Service Types
    SERVICE_TYPES = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT     FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY  FEDEX_FREIGHT_PRIORITY  FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY  INTERNATIONAL_ECONOMY  INTERNATIONAL_ECONOMY_FREIGHT  INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY  INTERNATIONAL_PRIORITY_FREIGHT  PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT)
    
    # List of available Packaging Type
    PACKAGING_TYPE = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING)
    
    # List of available DropOffTypes
    DROPOFFTYPE = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION)
    
    # In order to use Fedex rates API you must first apply for a developer(and later production keys), 
    # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - Fedex web service key
    # @param [String] password - Fedex password
    # @param [String] account_number - Fedex account_number
    # @param [String] meter - Fedex meter number    
    # @param [String] mode - [development/production]
    # 
    # return a Fedex::Shipment object
    def initialize(options={})
      requires!(options, :key, :password, :account_number, :meter, :mode)
      @key = options[:key]
      @password = options[:password] 
      @account_number = options[:account_number] 
      @meter = options[:meter]
      @mode = options[:mode]
    end
    
    
    # @param [Hash] shipper, A hash containing the shipper information
    # @param [Hash] recipient, A hash containing the recipient information
    # @param [Array] packages, An arrary including a hash for each package being shipped
    # @param [String] service_type, A valid fedex service type, to view a complete list of services Fedex::Shipment::SERVICE_TYPES
    def rate(options = {})
      requires!(options, :shipper, :recipient, :packages, :service_type)
      @shipper, @recipient, @packages, @service_type, @extra_options = options[:shipper], options[:recipient], options[:packages], options[:service_type], options[:extra_options]
      process_request
    end
    
    # Sends post request to Fedex web service and parse the response, a Rate object is created if the response is successful 
    def process_request
      api_response = Shipment.post(api_url, :body => build_xml)
      response = parse_response(api_response)
      if success?(response) 
        rate_details = [response[:rate_reply][:rate_reply_details][:rated_shipment_details]].flatten.first[:shipment_rate_detail]
        rate = Fedex::Rate.new(rate_details)
    else
        error_message = (response[:rate_reply].nil? ? api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"] : response[:rate_reply][:notifications][:message]) rescue "Unexpected error has occurred"
        raise StandardError, error_message 
      end
    end
    
    # Build xml Fedex Web Service request
    def build_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.RateRequest(:xmlns => "http://fedex.com/ws/rate/v10"){
          add_web_authentication_detail(xml)
          add_client_detail(xml)
          add_version(xml)
          add_requested_shipment(xml)
        }
      end
      builder.doc.root.to_xml
    end
    
    # Fedex Web Service Api
    def api_url
      @mode == "production" ? PRODUCTION_URL : TEST_URL
    end
    
    private
    # Helper method to validate required fields
    def requires!(hash, *params)
       params.each { |param| raise ArgumentError, "Missing Required Parameter #{param}" if hash[param].nil? }
    end
    
    def camelize(str) #:nodoc:
      str.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
    # Add web authentication detail information(key and password) to xml request
    def add_web_authentication_detail(xml)
      xml.WebAuthenticationDetail{
        xml.UserCredential{
          xml.Key @key
          xml.Password @password
        }
      }
    end
    
    # Add Client Detail information(account_number and meter_number) to xml request
    def add_client_detail(xml)
      xml.ClientDetail{
        xml.AccountNumber @account_number
        xml.MeterNumber @meter
      }
    end
    
    # Add Version to xml request, using the latest version V10 Sept/2011
    def add_version(xml)
      xml.Version{
        xml.ServiceId 'crs'
        xml.Major VERSION
        xml.Intermediate 0
        xml.Minor 0
      }
    end
    
    # Add information for shipments
    def add_requested_shipment(xml)
      xml.RequestedShipment{
        xml.DropoffType @extra_options[:drop_off_type] ||= "REGULAR_PICKUP"
        xml.ServiceType @service_type
        xml.PackagingType @extra_options[:packaging_type] ||= "YOUR_PACKAGING"
        add_shipper(xml)
        add_recipient(xml)
        add_shipping_charges_payment(xml)
        add_commodities(xml) if @commoditites
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
          xml.StreetLines @shipper[:address]
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
          xml.StreetLines @recipient[:address]
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
        xml.PaymentType "SENDER"
        xml.Payor{
          xml.AccountNumber @account_number
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
          xml.Dimensions{
            xml.Length package[:dimensions][:length]
            xml.Width package[:dimensions][:width]
            xml.Height package[:dimensions][:height]
            xml.Units package[:dimensions][:units]
          }
        }  
      end  
    end
    
    # Note: this method has not been implemented
    def add_commodities(xml)
      xml.CustomsClearanceDetail{
        xml.Broker{
          xml.AccountNumber @account_number
          xml.Tins {
            xml.TinType "BUSINESS_NATIONAL" 
            xml.Number "123456"
            xml.Usage "Usage"
          }
        }
        xml.DutiesPayment{
          xml.PaymentType "SENDER"
          xml.Payor{
            xml.AccountNumber @account_number
            xml.CountryCode @shipper[:country_code]
          }
        }  
        xml.Commodities{
           xml.Name 2
           xml.NumberOfPieces 2
           xml.Description "Cotton Coat"
           xml.CountryOfManufacture "US"
           xml.HarmonizedCode "6103320000"
           xml.Weight {
             xml.Units "LB"
             xml.Value 2
           }
           xml.Quantity 3
           xml.UnitPrice {
             xml.Currency "US"
             xml.Amount "50"
           }
           xml.CustomsValue {
             xml.Currency "US"
             xml.Amount "50"
           }
        }
      }
      
    end
    
    # Parse response, convert keys to underscore symbols
    def parse_response(response)
      response = sanitize_response_keys(response)
    end

    # Recursively sanitizes the response object by clenaing up any hash keys.
    def sanitize_response_keys(response)
      if response.is_a?(Hash)
        response.inject({}) { |result, (key, value)| result[underscorize(key).to_sym] = sanitize_response_keys(value); result } 
      elsif response.is_a?(Array)
        response.collect { |result| sanitize_response_keys(result) }
      else
        response
      end
    end

    def underscorize(key) #:nodoc:
      key.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
    end
    
    # Successful request
    def success?(response)
      (!response[:rate_reply].nil? and %w{SUCCESS WARNING NOTE}.include? response[:rate_reply][:highest_severity])
    end
    
  end
end