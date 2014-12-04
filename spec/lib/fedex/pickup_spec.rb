require 'spec_helper'
require 'fedex/shipment'

describe Fedex::Request::Pickup do
  describe "pickup service" do
    let(:fedex) { Fedex::Shipment.new(fedex_production_credentials) }
    let(:pickup_location) do
      {:name => "Sender", :company => "Company", :phone_number => "555-555-5555 ", :address => "Main Street",
       :city => "Mumbai", :state => "MH", :postal_code => "400012", :country_code => "IN"}
    end
    let(:packages) do
      {:weight => {:units => "LB", :value => 2}, :count => 2}
    end
    let(:ready_timestamp) { DateTime.now + 1 }
    let(:close_time) { DateTime.now + 1.2 }

    context "alternate address", :vcr do
      let(:options) do
        {:carrier_code => "FDXE", :packages => packages, :ready_timestamp => ready_timestamp,
         :close_time => close_time, :pickup_location => pickup_location, :remarks => 'TEST. DO NOT PICKUP', :commodity_description => 'Ladies Item as per invoice',
         :country_relationship => 'DOMESTIC'
       }
      end

      it "succeeds" do
        expect {
          @pickup = fedex.pickup(options)
        }.to_not raise_error
      end
    end
  end
end
