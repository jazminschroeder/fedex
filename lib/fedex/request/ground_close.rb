require 'fedex/request/base'
require 'fedex/ground_manifest'

module Fedex
  module Request
    class GroundClose < Base

      attr_reader :up_to_time, :filename

      def initialize(credentials, options={})
        requires!(options, :up_to_time)

        @credentials = credentials
        @up_to_time = options[:up_to_time]
        @filename = options[:filename]
        @debug = ENV['DEBUG'] == 'true'
      end

      def process_request
        api_response = self.class.post(api_url, :body => build_xml)
        puts api_response if @debug == true
        response = parse_response(api_response)
        if success?(response)
          success_response(response)
        else
          error_message = if response[:ground_close_reply]
            [response[:ground_close_reply][:notifications]].flatten.first[:message]
          else
            "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n
            --#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
          end rescue $1
          raise RateError, error_message
        end
      end

      private

      def success_response(response)
        manifest_details = {
          :filename => filename,
          :manifest => response[:ground_close_reply][:manifest]
        }
        manifest = Fedex::GroundManifest.new(manifest_details)
        puts "manifest written to #{filename}" if @debug == true
        manifest
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GroundCloseRequest(:xmlns => "http://fedex.com/ws/close/v2"){
            add_web_authentication_detail(xml)
            add_client_detail(xml)
            add_version(xml)

            xml.TimeUpToWhichShipmentsAreToBeClosed up_to_time.utc.iso8601(2)
          }
        end
        builder.doc.root.to_xml
      end

      def service
        { :id => 'clos', :version => '2' }
      end

      # Successful request
      def success?(response)
        response[:ground_close_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:ground_close_reply][:highest_severity])
      end
    end
  end
end
