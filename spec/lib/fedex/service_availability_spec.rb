# frozen_string_literal: true

require 'spec_helper'

module Fedex
  describe 'ServiceAvailability' do
    let(:fedex)  { Shipment.new(fedex_development_credentials) }
    let(:origin) { { postal_code: '400012', country_code: 'IN' } }
    let(:destination) { { postal_code: '400020', country_code: 'IN' } }
    let(:options) { { origin: origin, destination: destination, ship_date: '2014-06-28', carrier_code: 'FDXE' } }

    context 'Check Availability', :vcr do
      it 'succeeds' do
        expect do
          @service_availability = fedex.service_availability(options)
        end.to_not raise_error

        expect(@service_availability.class).not_to eq(Fedex::RateError)
      end
    end
  end
end
