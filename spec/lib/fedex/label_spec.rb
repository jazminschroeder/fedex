require 'spec_helper'
require 'tmpdir'
module Fedex
  describe Label do
    describe "ship service for label" do
      let(:fedex) { Shipment.new(fedex_credentials) }
      let(:shipper) do
        {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US"}
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

      let(:label_specification) do
        { :label_format_type => 'COMMON2D',
          :image_type => 'PDF',
        }
      end

      let(:filename) {
        require 'tmpdir'
        File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
      }

      let(:options) do
        { :shipper => shipper,
          :recipient => recipient,
          :packages => packages,
          :service_type => "FEDEX_GROUND",
          :label_specification => label_specification,
          :filename =>  filename
        }
      end

      describe "label", :vcr do
        before do
          @label = fedex.label(options)
        end

        it "should create a label" do
          File.should exist(filename)
        end

        it "should return tracking number" do
          @label.should respond_to('tracking_number')
        end

        it "should expose complete response" do
          @label.should respond_to('response_details')
        end
        after do
          require 'fileutils'
          FileUtils.rm_r(filename) if File.exist?(filename)
        end

        it "should expose the file_name" do
          @label.should respond_to('file_name')
        end
      end

      describe "smartpost", :vcr do
        let(:smartpost_details) do
          { :indicia => "PARCEL_SELECT",
            :ancillary_endorsement => "RETURN_SERVICE",
            :hub_id => "5531"}
        end

        let(:options) do
          { :shipper => shipper,
            :recipient => recipient,
            :packages => packages,
            :service_type => "SMART_POST",
            :label_specification => label_specification,
            :smartpost_details => smartpost_details,
            :filename =>  filename
          }
        end

        it 'creates label' do
          label = fedex.label(options)
          File.should exist(filename)
        end
      end

    end
  end
end
