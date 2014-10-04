require 'spec_helper'

module Fedex
  describe Shipment do
    let (:fedex) { Shipment.new(fedex_credentials) }

    let(:filename) {
      require 'tmpdir'
      File.join(Dir.tmpdir, "manifest#{rand(15000)}.txt")
    }

    context "#ground_close" do
      context "with shipment ready for close", :vcr do
        before do
          shipper = { :name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US" }
          recipient = { :name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
          packages = [
            {
              :weight => {:units => "LB", :value => 2},
              :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
            }
          ]
          # require 'tmpdir'
          # filename = File.join(Dir.tmpdir, "label#{rand(15000)}.pdf")
          options = { :shipper => shipper, :recipient => recipient, :packages => packages, :service_type => "FEDEX_GROUND"}#, :filename => filename }
          fedex.ship(options)
        end

        it "completes with success result" do
          # When running this spec you may need to uncomment the line below to allow shipment to be created before close request
          #sleep(7)
          expect{ fedex.ground_close(:up_to_time => Time.now, :filename => filename) }.to_not raise_error
        end
      end
      context "raise an error when there aren't any existing shipments to close", :vcr do
        it "raises an error" do
          expect { fedex.ground_close(:up_to_time => Time.now) }.to raise_error(Fedex::RateError, 'No Shipments to Close')
        end
      end
    end
  end
end
