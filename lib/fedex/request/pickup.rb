require 'fedex/request/common'

module Fedex
  module Request
    class Pickup < Common
      attr_reader :response_details

      def initialize(credentials, options={})
        super

        # Require compulsory parameters
        requires!(options, :contact_name, :company_name, :phone_number, :address, :city, :state, :postal_code, :country, :total_weight, :package_count)
        requires!(options, :ready_time_stamp, :company_close_time)

        # Compulsory parameters
        @address = {}
        @address[:address], @address[:city], @address[:state], @address[:postal_code], @address[:country] = options[:address], options[:city], options[:state], options[:postal_code], options[:country]
        @contact_name, @company_name, @phone_number, @total_weight, @package_count = options[:contact_name], options[:company_name], options[:phone_number], options[:total_weight], options[:package_count]
        @ready_time_stamp, @company_close_time, @debug = options[:ready_time_stamp], options[:company_close_time], options[:debug]

        # Optional parameters
        @oversize_package_count = options[:oversize_package_count] || 0
        @carrier_code = options[:carrier_code] || "FDXE"
        @weight_unit = options[:weight_unit] || "KG"
        @package_location, @building_part, @building_part_description, @remarks = options[:package_location], options[:building_part], options[:building_part_description], options[:remarks]
      end

      # Sends post request to Fedex web service and parse the response.
      # The parsed Fedex response is available in #response_details
      def process_request
        xml = build_xml
        puts xml if @debug
        api_response = self.class.post api_url, :body => xml
        puts api_response if @debug
        response = parse_response(api_response)
        if success?(response)
          success_response(api_response, response)
        else
          failure_response(api_response, response)
        end
      end

      private

      # Add information for pickup request
      def add_requested_pickup(xml)
        xml.OriginDetail{
          xml.PickupLocation {
            xml.Contact {
              xml.PersonName @contact_name
              xml.CompanyName @company_name
              xml.PhoneNumber @phone_number
            }
            xml.Address{
              Array(@address[:address]).take(2).each do |address_line|
                xml.StreetLines address_line
              end
              xml.City                @address[:city]
              xml.StateOrProvinceCode @address[:state]
              xml.PostalCode          @address[:postal_code]
              xml.CountryCode         @address[:country]
            }
          }
          xml.PackageLocation @package_location.to_s if @package_location
          xml.BuildingPart @building_part.to_s if @building_part
          xml.BuildingPartDescription @building_part_description.to_s if @building_part_description
          xml.ReadyTimestamp @ready_time_stamp.to_s
          xml.CompanyCloseTime @company_close_time.to_s
        }
        xml.PackageCount @package_count.to_s
        xml.TotalWeight {
          xml.Units @weight_unit.to_s
          xml.Value @total_weight.to_s
        }
        xml.CarrierCode @carrier_code.to_s
        xml.OversizePackageCount @oversize_package_count.to_s
        xml.Remarks @remarks.to_s if @remarks
      end

      # Callback used after a failed pickup response.
      def failure_response(api_response, response)
        error_message = if response[:create_pickup_reply]
          [response[:create_pickup_reply][:notifications]].flatten.first[:message]
        else
          "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
        end rescue $1
        raise FedexError, error_message
      end

      # Callback used after a successful pickup response.
      def success_response(api_response, response)
        @response_details = response[:create_pickup_reply]
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.CreatePickupRequest(:xmlns => "http://fedex.com/ws/pickup/v#{service[:version]}"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_requested_pickup(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'disp', :version => Fedex::PICKUP_API_VERSION }
      end

      # Successful request
      def success?(response)
        response[:create_pickup_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:create_pickup_reply][:highest_severity])
      end

    end
  end
end
