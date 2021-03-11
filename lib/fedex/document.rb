# frozen_string_literal: true

module Fedex
  class Document
    attr_reader :tracking_number, :filenames, :response_details, :request_xml, :response_xml

    # Initialize Fedex::Document Object
    # @param [Hash] options
    def initialize(shipment_details = {}, request_xml: '', response_xml: '')
      @response_details = shipment_details[:process_shipment_reply]
      @filenames = shipment_details[:filenames]
      @request_xml = request_xml unless request_xml.empty?
      @response_xml = response_xml unless response_xml.empty?

      # extract label and tracking number
      package_details = @response_details[:completed_shipment_detail][:completed_package_details]
      label = package_details[:label]
      @tracking_number = package_details[:tracking_ids][:tracking_number]

      # extract shipment documents
      shipment_documents = @response_details[:completed_shipment_detail][:shipment_documents] || []

      # unify iteration interface
      shipment_documents = [shipment_documents] unless shipment_documents.is_a?(Array)

      # keeps the filenames which actually saved
      save(@filenames[:label], label)

      # save shipment documents
      shipment_documents.each do |doc|
        doc_type = doc[:type].downcase.to_sym
        save(@filenames[doc_type], doc)
      end
    end

    def save(path, content)
      return unless path && has_image?(content)

      image = Base64.decode64(content[:parts][:image])
      full_path = Pathname.new(path)
      File.open(full_path, 'wb') do |f|
        f.write(image)
      end

      full_path
    end

    def has_image?(content)
      content[:parts] && content[:parts][:image]
    end
  end
end
