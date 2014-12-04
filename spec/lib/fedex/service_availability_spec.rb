require 'spec_helper'

module Fedex
  describe 'ServiceAvailability' do
    let(:fedex)  { Shipment.new(fedex_credentials) }
    let(:origin) do {:postal_code => '400012', :country_code => 'IN'} end
    let(:destination) do { :postal_code => '400020', :country_code => 'IN'} end
    let(:options) do {:origin => origin, :destination => destination, :ship_date => '2014-06-28', :carrier_code => 'FDXE'} end

    context 'Check Availability', :vcr do
      it "succeeds" do
        expect {
            @service_availability = fedex.service_availability(options)
          }.to_not raise_error

        expect(@service_availability.class).not_to eq(Fedex::RateError)
      end
    end
  end
end
