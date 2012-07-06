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

    context "domestic shipment", :vcr do
      let(:filename) {
        require 'tmpdir'
        File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
      }
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

  end
end
