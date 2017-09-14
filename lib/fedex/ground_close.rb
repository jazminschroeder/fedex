require 'base64'

module Fedex
  class GroundClose
    attr_accessor :manifest, :response_details

    # Initialize Fedex::Close Object
    # @param [Hash] options
    def initialize(close_details = {})
      @response_details = close_details[:ground_close_reply]
      @manifest = Base64.decode64(@response_details[:manifest][:file]) if @response_details[:manifest] && @response_details[:manifest][:file]
    end
  end
end
