require 'fedex/rate'
require 'fedex/request/common'

module Fedex
  module Request
    class Base < Common
      # List of available Service Types
      SERVICE_TYPES = %w(EUROPE_FIRST_INTERNATIONAL_PRIORITY FEDEX_1_DAY_FREIGHT FEDEX_2_DAY FEDEX_2_DAY_AM FEDEX_2_DAY_FREIGHT FEDEX_3_DAY_FREIGHT FEDEX_EXPRESS_SAVER FEDEX_FIRST_FREIGHT FEDEX_FREIGHT_ECONOMY FEDEX_FREIGHT_PRIORITY FEDEX_GROUND FIRST_OVERNIGHT GROUND_HOME_DELIVERY INTERNATIONAL_ECONOMY INTERNATIONAL_ECONOMY_FREIGHT INTERNATIONAL_FIRST INTERNATIONAL_PRIORITY INTERNATIONAL_PRIORITY_FREIGHT PRIORITY_OVERNIGHT SMART_POST STANDARD_OVERNIGHT)

      # List of available Packaging Type
      PACKAGING_TYPES = %w(FEDEX_10KG_BOX FEDEX_25KG_BOX FEDEX_BOX FEDEX_ENVELOPE FEDEX_PAK FEDEX_TUBE YOUR_PACKAGING)

      # List of available DropOffTypes
      DROP_OFF_TYPES = %w(BUSINESS_SERVICE_CENTER DROP_BOX REGULAR_PICKUP REQUEST_COURIER STATION)

      # Clearance Brokerage Type
      CLEARANCE_BROKERAGE_TYPE = %w(BROKER_INCLUSIVE BROKER_INCLUSIVE_NON_RESIDENT_IMPORTER BROKER_SELECT BROKER_SELECT_NON_RESIDENT_IMPORTER BROKER_UNASSIGNED)

      # Recipient Custom ID Type
      RECIPIENT_CUSTOM_ID_TYPE = %w(COMPANY INDIVIDUAL PASSPORT)

      # List of available Payment Types
      PAYMENT_TYPE = %w(RECIPIENT SENDER THIRD_PARTY)

      # In order to use Fedex rates API you must first apply for a developer(and later production keys),
      # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
      # @param [String] key - Fedex web service key
      # @param [String] password - Fedex password
      # @param [String] account_number - Fedex account_number
      # @param [String] meter - Fedex meter number
      # @param [String] mode - [development/production]
      #
      # return a Fedex::Request::Base object
      def initialize(credentials, options={})
        super
        requires!(options, :shipper, :recipient, :packages)
        @shipper, @recipient, @origin, @packages, @service_type, @customs_clearance_detail, @debug = options[:shipper], options[:recipient], options[:origin], options[:packages], options[:service_type], options[:customs_clearance_detail], options[:debug]
        @shipping_options =  options[:shipping_options] ||={}
        @payment_options = options[:payment_options] ||={}
        requires!(@payment_options, :type, :account_number, :name, :company, :phone_number, :country_code) if @payment_options.length > 0
        if options.has_key?(:mps)
          @mps = options[:mps]
          requires!(@mps, :package_count, :total_weight, :sequence_number)
          requires!(@mps, :master_tracking_id) if @mps.has_key?(:sequence_number) && @mps[:sequence_number].to_i >= 2
        else
          @mps = {}
        end
      end

      private
      # Add information for shipments
      def add_requested_shipment(xml)
        xml.RequestedShipment{
          xml.DropoffType @shipping_options[:drop_off_type] ||= "REGULAR_PICKUP"
          xml.ServiceType service_type
          xml.PackagingType @shipping_options[:packaging_type] ||= "YOUR_PACKAGING"
          add_shipper(xml)
          add_recipient(xml)
          add_shipping_charges_payment(xml)
          add_customs_clearance(xml) if @customs_clearance_detail
          xml.RateRequestTypes "ACCOUNT"
          add_packages(xml)
        }
      end

      # Add shipper to xml request
      def add_shipper(xml)
        xml.Shipper{
          xml.Contact{
            xml.PersonName @shipper[:name]
            xml.CompanyName @shipper[:company]
            xml.PhoneNumber @shipper[:phone_number]
          }
          xml.Address {
            Array(@shipper[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @shipper[:city]
            xml.StateOrProvinceCode @shipper[:state]
            xml.PostalCode @shipper[:postal_code]
            xml.CountryCode @shipper[:country_code]
          }
        }
      end

      # Add origin to xml request
      def add_origin(xml)
        xml.Origin{
          xml.Contact{
            xml.PersonName @origin[:name]
            xml.CompanyName @origin[:company]
            xml.PhoneNumber @origin[:phone_number]
          }
          xml.Address {
            Array(@origin[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @origin[:city]
            xml.StateOrProvinceCode @origin[:state]
            xml.PostalCode @origin[:postal_code]
            xml.CountryCode @origin[:country_code]
          }
        }
      end

      # Add recipient to xml request
      def add_recipient(xml)
        xml.Recipient{
          xml.Contact{
            xml.PersonName @recipient[:name]
            xml.CompanyName @recipient[:company]
            xml.PhoneNumber @recipient[:phone_number]
          }
          xml.Address {
            Array(@recipient[:address]).take(2).each do |address_line|
              xml.StreetLines address_line
            end
            xml.City @recipient[:city]
            xml.StateOrProvinceCode @recipient[:state]
            xml.PostalCode @recipient[:postal_code]
            xml.CountryCode @recipient[:country_code]
            xml.Residential @recipient[:residential]
          }
        }
      end

      # Add shipping charges to xml request
      def add_shipping_charges_payment(xml)
        xml.ShippingChargesPayment{
          xml.PaymentType @payment_options[:type] || "SENDER"
          xml.Payor{
            if service[:version].to_i >= Fedex::API_VERSION.to_i
              xml.ResponsibleParty {
                xml.AccountNumber @payment_options[:account_number] || @credentials.account_number
                xml.Contact {
                  xml.PersonName @payment_options[:name] || @shipper[:name]
                  xml.CompanyName @payment_options[:company] || @shipper[:company]
                  xml.PhoneNumber @payment_options[:phone_number] || @shipper[:phone_number]
                }
              }
            else
              xml.AccountNumber @payment_options[:account_number] || @credentials.account_number
              xml.CountryCode @payment_options[:country_code] || @shipper[:country_code]
            end
          }
        }
      end

      # Add Master Tracking Id (for MPS Shipping Labels, this is required when requesting labels 2 through n)
      def add_master_tracking_id(xml)
        if @mps.has_key? :master_tracking_id
          xml.MasterTrackingId{
            xml.TrackingIdType @mps[:master_tracking_id][:tracking_id_type]
            xml.TrackingNumber @mps[:master_tracking_id][:tracking_number]
          }
        end
      end

      # Add packages to xml request
      def add_packages(xml)
        add_master_tracking_id(xml) if @mps.has_key? :master_tracking_id
        package_count = @packages.size
        if @mps.has_key? :package_count
          xml.PackageCount @mps[:package_count]
        else
          xml.PackageCount package_count
        end
        @packages.each do |package|
          xml.RequestedPackageLineItems{
            if @mps.has_key? :sequence_number
              xml.SequenceNumber @mps[:sequence_number]
            else
              xml.GroupPackageCount 1
            end
            if package[:insured_value]
              xml.InsuredValue{
                xml.Currency package[:insured_value][:currency]
                xml.Amount package[:insured_value][:amount]
              }
            end
            xml.Weight{
              xml.Units package[:weight][:units]
              xml.Value package[:weight][:value]
            }
            if package[:dimensions]
              xml.Dimensions{
                xml.Length package[:dimensions][:length]
                xml.Width package[:dimensions][:width]
                xml.Height package[:dimensions][:height]
                xml.Units package[:dimensions][:units]
              }
            end
            add_customer_references(xml, package)
            if package[:special_services_requested] && package[:special_services_requested][:special_service_types]
              xml.SpecialServicesRequested{
                if package[:special_services_requested][:special_service_types].is_a? Array
                  package[:special_services_requested][:special_service_types].each do |type|
                    xml.SpecialServiceTypes type
                  end
                else
                  xml.SpecialServiceTypes package[:special_services_requested][:special_service_types]
                end
                # Handle COD Options
                if package[:special_services_requested][:cod_detail]
                  xml.CodDetail{
                    xml.CodCollectionAmount{
                      xml.Currency package[:special_services_requested][:cod_detail][:cod_collection_amount][:currency]
                      xml.Amount package[:special_services_requested][:cod_detail][:cod_collection_amount][:amount]
                    }
                    if package[:special_services_requested][:cod_detail][:add_transportation_charges]
                      xml.AddTransportationCharges package[:special_services_requested][:cod_detail][:add_transportation_charges]
                    end
                    xml.CollectionType package[:special_services_requested][:cod_detail][:collection_type]
                    xml.CodRecipient {
                      add_shipper(xml)
                    }
                    if package[:special_services_requested][:cod_detail][:reference_indicator]
                      xml.ReferenceIndicator package[:special_services_requested][:cod_detail][:reference_indicator]
                    end
                  }
                end
                # DangerousGoodsDetail goes here
                if package[:special_services_requested][:dry_ice_weight]
                  xml.DryIceWeight{
                    xml.Units package[:special_services_requested][:dry_ice_weight][:units]
                    xml.Value package[:special_services_requested][:dry_ice_weight][:value]
                  }
                end
                if package[:special_services_requested][:signature_option_detail]
                  xml.SignatureOptionDetail{
                    xml.OptionType package[:special_services_requested][:signature_option_detail][:signature_option_type]
                  }
                end
                if package[:special_services_requested][:priority_alert_detail]
                  xml.PriorityAlertDetail package[:special_services_requested][:priority_alert_detail]
                end
              }
            end
          }
        end
      end

      def add_customer_references(xml, package)
        # customer_refrences is a legacy misspelling
        if refs = package[:customer_references] || package[:customer_refrences]
          refs.each do |ref|
            xml.CustomerReferences{
              if ref.is_a?(Hash)
                # :type can specify custom type:
                #
                # BILL_OF_LADING, CUSTOMER_REFERENCE, DEPARTMENT_NUMBER,
                # ELECTRONIC_PRODUCT_CODE, INTRACOUNTRY_REGULATORY_REFERENCE,
                # INVOICE_NUMBER, P_O_NUMBER, RMA_ASSOCIATION,
                # SHIPMENT_INTEGRITY, STORE_NUMBER
                xml.CustomerReferenceType ref[:type]
                xml.Value                 ref[:value]
              else
                xml.CustomerReferenceType 'CUSTOMER_REFERENCE'
                xml.Value                 ref
              end
            }
          end
        end
      end

      # Add customs clearance(for international shipments)
      def add_customs_clearance(xml)
        xml.CustomsClearanceDetail{
          hash_to_xml(xml, @customs_clearance_detail)
        }
      end
    end
  end
end
