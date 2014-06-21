require 'spec_helper'

module Fedex
  describe Shipment do
    let (:fedex) { Shipment.new(fedex_credentials) }
    context "#delete" do
      context "delete shipment with tracking number", :vcr do
        let(:options) do
          { :tracking_number => '794608797150' }
        end
        it "deletes a shipment" do
          expect{ fedex.delete(options) }.to_not raise_error
        end
      end
      context "raise an error when the tracking number is invalid", :vcr do
        let(:options) do
          { :tracking_number => '111111111' }
        end

        it "raises an error" do
          expect {fedex.delete(options) }.to raise_error(Fedex::RateError, 'Invalid tracking number')
        end
      end
    end
  end
end
