# frozen_string_literal: true

require 'fedex/request/base'

module Fedex
  module Request
    class UploadImages < Base
      def initialize(credentials, options = {})
        requires!(options, :images)
        @debug = ENV['DEBUG'] == 'true'

        @credentials = credentials
        @images = options[:images]
      end

      def process_request
        api_response = self.class.post(api_url, body: build_xml)
        puts api_response if @debug
        response = parse_response(api_response)

        handle_response(api_response, response)
      end

      private

      def build_xml
        ns = "http://fedex.com/ws/uploaddocument/v#{service[:version]}"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.UploadImagesRequest(xmlns: ns) do
            add_standard_request_details(xml)

            add_images(xml)
          end
        end
        builder.doc.root.to_xml
      end

      def service
        { id: 'cdus', version: Fedex::UPLOAD_DOCUMENT_API_VERSION }
      end

      def add_images(xml)
        @images.each do |image_object|
          validate_image!(image_object[:image])

          xml.Images do
            xml.Id image_object[:id]
            xml.Image build_image_data(image_object[:image])
          end
        end
      end

      def build_image_data(image)
        Base64.strict_encode64(image.read)
      end

      def validate_image!(image)
        raise(RateError, 'Image must be a type of file') unless image.respond_to?(:read)
      end

      def handle_response(_api_response, response)
        @response_details = response[:upload_images_reply]
      end
    end
  end
end
