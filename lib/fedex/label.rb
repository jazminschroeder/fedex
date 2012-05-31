require 'base64'

module Fedex
  class Label
    attr_accessor :options, :image

    # Initialize Fedex::Label Object
    # @param [Hash] options
    def initialize(options = {})
      @options = options

      @image = Base64.decode64(options[:parts][:image]) if has_image?
    end

    def name
      [tracking_number, format].join('.')
    end

    def format
      options[:format]
    end

    def tracking_number
      options[:tracking_number]
    end

    def has_image?
      options[:parts] && options[:parts][:image]
    end

    def save(path)
      return unless has_image?

      full_path = File.join(path, label_name)

      File.open(full_path, 'wb') do|f|
        f.write(@image)
      end
    end
  end
end