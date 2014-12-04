require 'spec_helper'
require 'fedex/shipment'

describe Fedex::Request::Pickup do
  describe "pickup availability service" do
    let(:fedex) { Fedex::Shipment.new(fedex_credentials) }
    let(:dispatch_date) {(Date.today + 1).strftime('%Y-%m-%d')}

    let(:options) do
      {:country_code => 'IN', :postal_code => '400061', :request_type => 'FUTURE_DAY', :dispatch_date => dispatch_date, :carrier_code => 'FDXE'}
    end

    it "succeeds", :vcr do
      expect {
        @pickup_availability = fedex.pickup_availability(options)
      }.to_not raise_error
    end
  end
end
