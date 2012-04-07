module Fedex
  class Label
    attr_accessor :options

    # Initialize Fedex::Label Object
    # @param [Hash] options
    def initialize(options = {})
      @options = options
    end
  end
end