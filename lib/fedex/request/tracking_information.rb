require 'fedex/request/base'
require 'fedex/tracking_information'

module Fedex
  module Request
    class TrackingInformation < Base

      attr_reader :package_type, :package_id

      def initialize(credentials, options={})
        requires!(options, :package_type, :package_id) unless options.has_key?(:tracking_number)

        @package_id   = options[:package_id]   || options.delete(:tracking_number)
        @package_type = options[:package_type] || "TRACKING_NUMBER_OR_DOORTAG"
        @credentials  = credentials

        # Optional
        @include_detailed_scans = options[:include_detailed_scans] || true
        @uuid                   = options[:uuid]
        @paging_token           = options[:paging_token]

        unless package_type_valid?
          raise "Unknown package type '#{package_type}'"
        end
      end

      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)

        if success?(response)
          options = response[:track_reply][:track_details]

          if response[:track_reply][:duplicate_waybill].downcase == 'true'
            shipments = []
            [options].flatten.map do |details|
              options = {:tracking_number => @package_id, :uuid => details[:tracking_number_unique_identifier]}
              shipments << Request::TrackingInformation.new(@credentials, options).process_request
            end
            shipments.flatten
          else
            [options].flatten.map do |details|
              Fedex::TrackingInformation.new(details)
            end
          end
        else
          error_message = if response[:track_reply]
            response[:track_reply][:notifications][:message]
          else
            "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.TrackRequest(:xmlns => "http://fedex.com/ws/track/v#{service[:version]}"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)
            add_package_identifier(xml)
            xml.TrackingNumberUniqueIdentifier @uuid         if @uuid
            xml.IncludeDetailedScans           @include_detailed_scans
            xml.PagingToken                    @paging_token if @paging_token
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'trck', :version => 6 }
      end

      def add_package_identifier(xml)
        xml.PackageIdentifier{
          xml.Value package_id
          xml.Type  package_type
        }
      end

      # Successful request
      def success?(response)
        response[:track_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:track_reply][:highest_severity])
      end

      def package_type_valid?
        Fedex::TrackingInformation::PACKAGE_IDENTIFIER_TYPES.include? package_type
      end

    end
  end
end
