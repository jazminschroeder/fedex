require 'fedex/location'
require 'fedex/request/shipment'


module Fedex
  module Request
    class Location < Base
      def initialize(credentials, options = {})
        requires!(options, :address)

        @credentials = credentials
        @address = options[:address]
        @multiple_matches_action = options[:multiple_matches_action]
        @constraints = options[:constraints]
        options[:constraints].tap do |constraints|
          @radius_distance = constraints[:radius_distance]
          @required_location_attributes = constraints[:required_location_attributes]
          @results_requested = constraints[:results_requested]
          @results_to_skip = constraints[:results_to_skip]
          @supported_redirect_to_hold_services = constraints[:supported_redirect_to_hold_services]
        end

        @debug = ENV['DEBUG'] == 'true'
      end

      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response.to_json if @debug
        response = parse_response(api_response)
        if success?(response)
          atlr = response.dig(:search_locations_reply, :address_to_location_relationships, :distance_and_location_details)  #response[:search_locations_reply][:address_to_location_relationships][:disa]
          atlr = [atlr] if atlr.is_a? Hash
          atlr.map{|location|
            location_detail = location[:location_detail]
            Fedex::Location.new(location_detail) if  !!location_detail && !location_detail.empty?
          }.compact
        else
          error_message = if response[:search_locations_reply]
            [response[:search_locations_reply][:notifications]].flatten.first[:message]
          else
            "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
          end rescue $1
          raise LocationError, error_message
        end
      end

      def build_xml
            ns = "http://fedex.com/ws/locs/v#{service[:version]}"
            builder = Nokogiri::XML::Builder.new do |xml|
              xml.SearchLocationsRequest(:xmlns => ns){
                add_web_authentication_detail(xml)
                add_client_detail(xml)
                add_version(xml)
                add_location(xml)
              }
            end
            puts builder.doc.root.to_xml if @debug
            builder.doc.root.to_xml
      end

        def service
            { :id => 'locs', :version => Fedex::LOCATION_API_VERSION }
          end

      private

      def add_location(xml)
        xml.LocationsSearchCriterion "ADDRESS"
        xml.Address {
                xml.StreetLines @address[:street]
                xml.City @address[:city]
                xml.StateOrProvinceCode @address[:state]
                xml.PostalCode @address[:postal_code]
                xml.CountryCode @address[:country_code]
              }
              xml.MultipleMatchesAction(@multiple_matches_action) unless @multiple_matches_action.nil?
              xml.Constraints {
                xml.RadiusDistance {
                  xml.Value @radius_distance[:value]
                  xml.Units @radius_distance[:units]
                } unless @radius_distance.nil?
                @supported_redirect_to_hold_services.each{|val|
                  xml.SupportedRedirectToHoldServices(val)
                } unless @supported_redirect_to_hold_services.nil?
                @required_location_attributes.each{|val|
                  xml.RequiredLocationAttributes(val)
                } unless @required_location_attributes.nil?
                xml.ResultsToSkip(@results_to_skip) unless @results_to_skip.nil?
                xml.ResultsRequested(@results_requested) unless @results_requested.nil?
              } unless @constraints.nil?

      end

      # Successful request
        def success?(response)
        response[:search_locations_reply] && %w{SUCCESS WARNING NOTE}.include?(response[:search_locations_reply][:highest_severity])
        end
    end
  end
end
