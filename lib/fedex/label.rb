module Fedex
  class Label
    attr_accessor :options
    def initialize(options = {})
      @options = options
    end
  end
end