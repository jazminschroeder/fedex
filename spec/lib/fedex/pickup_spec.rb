require 'spec_helper'
require 'fedex/shipment'

describe Fedex::Request::Pickup do
  describe "pickup service" do
    let(:fedex) { Fedex::Shipment.new(fedex_credentials) }
    let(:pickup_location) do
      {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US"}
    end
    let(:packages) do
      {
        :weight => {:units => "LB", :value => 2},
        :count => 2
      }
    end
    let(:ready_timestamp) { Date.today.to_datetime + 1.375 } # 9 AM Tomorrow
    let(:close_time) { Date.today.to_time + 60 * 60 * 17 } # 5 PM

    context "alternate address", :vcr do
      let(:options) do
        {:carrier_code => "FDXE", :packages => packages, :ready_timestamp => ready_timestamp, :close_time => close_time, :pickup_location => pickup_location}
      end

      it "succeeds" do
        expect {
          @pickup = fedex.pickup(options)
        }.to_not raise_error

        @pickup.class.should_not == Fedex::RateError
      end
    end
  end
end
