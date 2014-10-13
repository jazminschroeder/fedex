require 'spec_helper'
require 'fedex/shipment'

module Fedex
  describe Request::PickupAvailability do
    let(:fedex) { Shipment.new(fedex_credentials) }
    let(:dispatch_date) {Date.tomorrow.strftime('%Y-%m-%d')}

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
