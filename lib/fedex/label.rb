require 'base64'
require 'pathname'

module Fedex
  class Label
    attr_accessor :options, :image, :response_details

    # Initialize Fedex::Label Object
    # @param [Hash] options
    def initialize(label_details = {}, associated_shipments = false)
      if associated_shipments
        package_details = label_details
        @options = package_details[:label]
        @options[:tracking_number] = package_details[:tracking_id]
      else
        @response_details = label_details[:process_shipment_reply]
        package_details = label_details[:process_shipment_reply][:completed_shipment_detail][:completed_package_details]
        @options = package_details[:label]
        @options[:tracking_number] = package_details[:tracking_ids][:tracking_number]
      end
      @options[:format] = label_details[:format]
      @options[:file_name] = label_details[:file_name]
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

    def file_name
      options[:file_name]
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

    def associated_shipments
      if (label_details = @response_details[:completed_shipment_detail][:associated_shipments]).present?
        label_details[:format] = format
        label_details[:file_name] = file_name
        Label.new(label_details, true)
      else
        nil
      end
    end
  end
end