require 'spec_helper'
require 'fedex/shipment'

describe Fedex::Request::Shipment do
  describe "ship service" do
    let(:fedex) { Fedex::Shipment.new(fedex_credentials) }
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


    let(:filename) {
      require 'tmpdir'
     p File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
    }

    context "domestic shipment", :vcr do
      let(:options) do
        {:shipper => shipper, :recipient => recipient, :packages => packages, :service_type => "FEDEX_GROUND", :filename => filename}
      end

      it "succeeds" do
        expect {
          @shipment = fedex.ship(options)
        }.to_not raise_error

        @shipment.class.should_not == Fedex::RateError
      end
    end

    context 'without service_type specified', :vcr do
      let(:options) do
        {:shipper => shipper, :recipient => recipient, :packages => packages, :filename => filename}
      end

      it 'raises error' do
        expect {
          @shipment = fedex.ship(options)
        }.to raise_error('Missing Required Parameter service_type')
      end

    end

    context 'smartpost', :vcr do
      let(:smartpost_details) do
        { :indicia => "PARCEL_SELECT",
          :ancillary_endorsement => "RETURN_SERVICE",
          :hub_id => "5531"}
      end

      let(:options) do
        {:shipper => shipper, :recipient => recipient, :packages => packages, :filename => filename, :service_type => "SMART_POST", :smartpost_details => smartpost_details, debug: true}
      end

      it "returns valid shipment" do
        shipment = fedex.ship(options)
        shipment.class.should_not == Fedex::RateError
      end

    end

  end
end
