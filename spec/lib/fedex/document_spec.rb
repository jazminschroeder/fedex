require 'spec_helper'
require 'tmpdir'

module Fedex
  describe Document do
    let(:fedex) { Shipment.new(fedex_credentials) }
    let(:shipper) do
      {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "King Street", :city => "Ashbourne", :postal_code => "DE6 1EA", :country_code => "GB"}
    end
    let(:recipient) do
      {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
    end
    let(:packages) do
      [
        {
          :weight => {:units => "LB", :value => 2},
          :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
        }
      ]
    end
    let(:shipping_options) do
      { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }
    end
    let(:customs) do
      {
        :duties_payment => {
          :payment_type => 'SENDER',
          :payor => {
            :responsible_party => {
              :account_number => fedex_credentials[:account_number],
              :contact => {
                :person_name => 'Mr. Test',
                :phone_number => '12345678'
              }
            }
          }
        },
        :document_content => 'NON_DOCUMENTS',
        :customs_value => {
          :currency => 'UKL', # UK Pounds Sterling
          :amount => 155.79
        },
        :commercial_invoice => {
          :terms_of_sale => 'DDU'
        },
        :commodities => [
          {
            :number_of_pieces => 1,
            :description => 'Pink Toy',
            :country_of_manufacture => 'GB',
            :weight => {
              :units => 'LB',
              :value => 2
            },
            :quantity => 1,
            :quantity_units => 'EA',
            :unit_price => {
              :currency => 'UKL',
              :amount => 155.79
            },
            :customs_value => {
              :currency => 'UKL', # UK Pounds Sterling
              :amount => 155.79
            }
          }
        ]
      }
    end
    let(:document) do
      {
        :shipping_document_types => 'COMMERCIAL_INVOICE',
        :commercial_invoice_detail => {
          :format => {
            :image_type => 'PDF',
            :stock_type => 'PAPER_LETTER'
          }
        }
      }
    end

    let(:filenames) {
      require 'tmpdir'
      {
        :label => File.join(Dir.tmpdir, "label#{rand(15000)}.pdf"),
        :commercial_invoice => File.join(Dir.tmpdir, "invoice#{rand(15000)}.pdf")
      }
    }

    let(:options) do
      {
        :shipper => shipper,
        :recipient => recipient,
        :packages => packages,
        :service_type => "INTERNATIONAL_PRIORITY",
        :shipping_details => shipping_options,
        :customs_clearance => customs,
        :shipping_document => document,
        :filenames => filenames
      }
    end

    describe 'document service', :vcr do

      context 'with document specification' do

        before do
          @document = fedex.document(options)
        end

        it "saves a label to file" do
          File.should exist(filenames[:label])
        end

        it "saves invoice to file" do
          File.should exist(filenames[:commercial_invoice])
        end

        it "returns tracking number" do
          @document.should respond_to('tracking_number')
        end

        it "exposes complete response" do
          @document.should respond_to('response_details')
        end

        it "exposes the filenames" do
          @document.should respond_to('filenames')
        end

      end

      context 'without document specification' do

        before do
          @document = fedex.document(
            options.reject{|k| k == :shipping_document}
          )
        end

        it "saves a label to file" do
          File.should exist(filenames[:label])
        end

        it "has no others files" do
          File.should_not exist(filenames[:commercial_invoice])
        end

      end

      context 'filename missed' do
        context 'for label' do
          before do
            filenames.delete(:label)
            @document = fedex.document(options)
          end

          it "saves invoice to file" do
            File.should exist(filenames[:commercial_invoice])
          end
        end

        context 'for invoice' do
          before do
            filenames.delete(:commercial_invoice)
            @document = fedex.document(options)
          end

          it "saves label to file" do
            File.should exist(filenames[:label])
          end
        end
      end

    end

  end
end
