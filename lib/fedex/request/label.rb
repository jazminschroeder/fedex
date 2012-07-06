require 'fedex/request/base'
require 'fedex/label'
require 'fedex/request/shipment'
require 'fileutils'

module Fedex
  module Request
    class Label < Shipment
      def initialize(credentials, options={})
        super(credentials, options)
        @filename = options[:filename]
      end

      private

      def success_response(api_response, response)
        super

        label_details = response.merge!({
          :format => @label_specification[:image_type],
          :file_name => @filename
        })

        Fedex::Label.new label_details
      end

    end
  end
end
