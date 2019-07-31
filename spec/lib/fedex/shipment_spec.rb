# frozen_string_literal: true

require 'spec_helper'
require 'fedex/shipment'

describe Fedex::Request::Shipment do
  describe 'ship service' do
    let(:fedex) { Fedex::Shipment.new(fedex_development_credentials) }
    let(:shipper) do
      {
        name: 'Sender',
        company: 'Company',
        phone_number: '555-555-5555',
        address: 'Main Street',
        city: 'Harrison',
        state: 'AR',
        postal_code: '72601',
        country_code: 'US',
        tins: {
          tin_type: 'BUSINESS_STATE',
          number: '213456'
        }
      }
    end
    let(:recipient) do
      { name: 'Recipient', company: 'Company', phone_number: '555-555-5555', address: 'Main Street', city: 'Frankin Park', state: 'IL', postal_code: '60131', country_code: 'US', residential: true }
    end
    let(:packages) do
      [
        {
          weight: { units: 'LB', value: 2 },
          dimensions: { length: 10, width: 5, height: 4, units: 'IN' }
        }
      ]
    end
    let(:shipping_options) do
      { packaging_type: 'YOUR_PACKAGING', drop_off_type: 'REGULAR_PICKUP' }
    end
    let(:payment_options) do
      { type: 'SENDER', account_number: fedex_development_credentials[:account_number], name: 'Sender', company: 'Company', phone_number: '555-555-5555', country_code: 'US' }
    end

    let(:filename) do
      require 'tmpdir'
      File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
    end

    context 'domestic shipment', :vcr do
      let(:options) do
        { shipper: shipper, recipient: recipient, packages: packages, service_type: 'FEDEX_GROUND', filename: filename }
      end

      it 'succeeds' do
        expect do
          @shipment = fedex.ship(options)
        end.to_not raise_error

        expect(@shipment.class).not_to eq(Fedex::RateError)
      end

      it 'succeeds with payments_options' do
        expect do
          @shipment = fedex.ship(options.merge(payment_options: payment_options))
        end.to_not raise_error

        expect(@shipment.class).not_to eq(Fedex::RateError)
      end

      it 'should return a transit time' do
        @shipment = fedex.ship(options)
        expect(@shipment[:completed_shipment_detail][:operational_detail][:transit_time]).to eql('TWO_DAYS')
      end
    end

    context 'without service_type specified', :vcr do
      let(:options) do
        { shipper: shipper, recipient: recipient, packages: packages, filename: filename }
      end

      it 'raises error' do
        expect do
          @shipment = fedex.ship(options)
        end.to raise_error('Missing Required Parameter service_type')
      end
    end

    context 'with invalid payment_options' do
      let(:options) do
        { shipper: shipper, recipient: recipient, packages: packages, filename: filename, payment_options: payment_options.merge(account_number: nil) }
      end

      it 'raises error' do
        expect do
          @shipment = fedex.ship(options)
        end.to raise_error('Missing Required Parameter account_number')
      end
    end
  end
end
