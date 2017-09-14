require 'fedex/request/base'
require 'fedex/ground_close'

module Fedex
  module Request
    class GroundClose < Base
      attr_accessor :manifest, :response_details

      def initialize(credentials, options={})
        @credentials  = credentials
        @debug = ENV['DEBUG'] == 'true'
      end

      # Sends post request to Fedex web service and parse the response, a Rate object is created if the response is successful
      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug
        response = parse_response(api_response)
        if success?(response) || (response[:ground_close_reply] && [response[:ground_close_reply][:notifications]].flatten.first[:code] == "9804") # No shipments to close
          Fedex::GroundClose.new(response)
        else
          error_message = if response[:ground_close_reply]
            [response[:ground_close_reply][:notifications]].flatten.first[:message]
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
          xml.GroundCloseRequest(:xmlns => "http://fedex.com/ws/close/v2"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)

            xml.TimeUpToWhichShipmentsAreToBeClosed Time.now.utc.iso8601(2)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'clos', :version => 2 }
      end

      # Successful request
      def success?(response)
        response[:ground_close_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:ground_close_reply][:highest_severity])
      end
    end
  end
end
