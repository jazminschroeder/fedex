# frozen_string_literal: true

require 'fedex/request/base'

module Fedex
  module Request
    class Shipment < Base
      attr_reader :response_details, :request_xml, :response_xml

      def initialize(credentials, options = {})
        super
        requires!(options, :service_type)
        # Label specification is required even if we're not using it.
        @label_specification = {
          label_format_type: 'COMMON2D',
          image_type: 'PDF',
          label_stock_type: 'PAPER_LETTER'
        }
        @label_specification.merge! options[:label_specification] if options[:label_specification]
        @customer_specified_detail = options[:customer_specified_detail] if options[:customer_specified_detail]
      end

      # Sends post request to Fedex web service and parse the response.
      # A label file is created with the label at the specified location.
      # The parsed Fedex response is available in #response_details
      # e.g. response_details[:completed_shipment_detail][:completed_package_details][:tracking_ids][:tracking_number]
      def process_request
        @request_xml = build_xml
        @response_xml = self.class.post api_url, body: @request_xml
        puts @response_xml if @debug
        response = parse_response(@response_xml.dup)
        if success?(response)
          success_response(@response_xml, response)
        else
          failure_response(@response_xml, response, @request_xml)
        end
      end

      private

      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment  do
          xml.ShipTimestamp @shipping_options[:ship_timestamp] ||= Time.now.utc.iso8601(2)
          xml.DropoffType @shipping_options[:drop_off_type] ||= 'REGULAR_PICKUP'
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= 'YOUR_PACKAGING'
          add_total_weight(xml) if @mps.key? :total_weight
          add_shipper(xml)
          add_origin(xml) if @origin
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_shipment_special_service_type(xml)
          add_special_services(xml) if special_services_requested?
          add_customs_clearance(xml) if @customs_clearance_detail
          add_custom_components(xml)

          xml.RateRequestTypes 'NONE'
          add_packages(xml)
        end
      end

      def add_total_weight(xml)
        if @mps.key? :total_weight
          xml.TotalWeight  do
            xml.Units @mps[:total_weight][:units]
            xml.Value @mps[:total_weight][:value]
          end
        end
      end

      # Hook that can be used to add custom parts.
      def add_custom_components(xml)
        add_label_specification xml
      end

      # Add the label specification
      def add_label_specification(xml)
        xml.LabelSpecification do
          xml.LabelFormatType @label_specification[:label_format_type]
          xml.ImageType @label_specification[:image_type]
          xml.LabelStockType @label_specification[:label_stock_type]
          xml.CustomerSpecifiedDetail { hash_to_xml(xml, @customer_specified_detail) } if @customer_specified_detail

          if @label_specification[:printed_label_origin] && @label_specification[:printed_label_origin][:address]
            xml.PrintedLabelOrigin do
              xml.Contact do
                xml.PersonName @label_specification[:printed_label_origin][:address][:name]
                xml.CompanyName @label_specification[:printed_label_origin][:address][:company]
                xml.PhoneNumber @label_specification[:printed_label_origin][:address][:phone_number]
              end
              xml.Address do
                Array(@label_specification[:printed_label_origin][:address][:address]).each do |address_line|
                  xml.StreetLines address_line
                end
                xml.City @label_specification[:printed_label_origin][:address][:city]
                xml.StateOrProvinceCode @label_specification[:printed_label_origin][:address][:state]
                xml.PostalCode @label_specification[:printed_label_origin][:address][:postal_code]
                xml.CountryCode @label_specification[:printed_label_origin][:address][:country_code]
              end
            end
          end
        end
      end

      def add_special_services(xml)
        xml.SpecialServicesRequested do
          if @shipping_options[:return_reason]
            xml.SpecialServiceTypes 'RETURN_SHIPMENT'
            xml.ReturnShipmentDetail do
              xml.ReturnType 'PRINT_RETURN_LABEL'
              xml.Rma do
                xml.Reason (@shipping_options[:return_reason]).to_s
              end
            end
          end

          if @shipping_options[:cod]
            xml.SpecialServiceTypes 'COD'
            xml.CodDetail do
              xml.CodCollectionAmount do
                xml.Currency @shipping_options[:cod][:currency].upcase if @shipping_options[:cod][:currency]
                xml.Amount @shipping_options[:cod][:amount] if @shipping_options[:cod][:amount]
              end
              xml.CollectionType @shipping_options[:cod][:collection_type] if @shipping_options[:cod][:collection_type]
            end
          end

          xml.SpecialServiceTypes 'SATURDAY_DELIVERY' if @shipping_options[:saturday_delivery]

          if @shipping_options[:electronic_trade_documents]
            xml.SpecialServiceTypes 'ELECTRONIC_TRADE_DOCUMENTS'

            if @shipping_options[:electronic_trade_documents][:requested_document_copies]
              xml.EtdDetail do
                xml.RequestedDocumentCopies @shipping_options[:electronic_trade_documents][:requested_document_copies]
              end
            end
          end
        end
      end

      # Callback used after a failed shipment response.
      def failure_response(api_response, response, request)
        error_message = begin
                          if response[:process_shipment_reply]
                            [response[:process_shipment_reply][:notifications]].flatten.first[:message]
                          else
                            "#{api_response["Fault"]["detail"]["fault"]["reason"]}\n--#{api_response["Fault"]["detail"]["fault"]["details"]["ValidationFailureDetail"]["message"].join("\n--")}"
                          end
                        rescue StandardError
                          $1
                        end
        raise RateError.new(error_message, api_response, request)
      end

      # Callback used after a successful shipment response.
      def success_response(_api_response, response)
        @response_details = response[:process_shipment_reply]
      end

      # Build xml Fedex Web Service request
      def build_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.ProcessShipmentRequest(xmlns: "http://fedex.com/ws/ship/v#{service[:version]}")  do
            add_standard_request_details(xml)

            add_requested_shipment(xml)
          end
        end
        builder.doc.root.to_xml
      end

      def special_services_requested?
        @shipping_options[:return_reason] ||
          @shipping_options[:cod] ||
          @shipping_options[:saturday_delivery] ||
          @shipping_options[:electronic_trade_documents]
      end

      def service
        { id: 'ship', version: Fedex::API_VERSION }
      end

      # Successful request
      def success?(response)
        response[:process_shipment_reply] &&
          %w{SUCCESS WARNING NOTE}.include?(response[:process_shipment_reply][:highest_severity])
      end
    end
  end
end
