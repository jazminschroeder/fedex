require 'base64'
require 'pathname'

module Fedex
  class Label
    attr_accessor :options, :image

    # Initialize Fedex::Label Object
    # @param [Hash] options
    def initialize(options = {})
      @options = options

      @image = Base64.decode64(options[:parts][:image]) if has_image?

      if file_name = @options[:file_name]
        save(file_name, false)
      end
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

    def save(path, append_name = true)
      return unless has_image?

      full_path = Pathname.new(path)
      full_path = full_path.join(name) if append_name

      File.open(full_path, 'wb') do|f|
        f.write(@image)
      end
    end
  end
end