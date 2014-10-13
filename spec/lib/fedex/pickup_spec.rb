require 'spec_helper'
require 'fedex/pickup'
require 'date'

describe Fedex::Request::Pickup do
  describe "pickup service" do

    let(:fedex) { Fedex::Pickup.new(fedex_credentials) }

    context "scheduled pickup", :vcr do

      let(:options) do
        {
          contact_name: "Test Tester",
          company_name: "Test Company",
          phone_number: "+358501234567",
          address: [
            "6th Floor",
            "Lonnrotinkatu 5"
          ],
          city: "Helsinki",
          postal_code: "00120",
          state: "",
          country: "FI",
          package_count: 2,
          total_weight: 18,
          ready_time_stamp: loop do
            day = DateTime.now+rand(3)        # Fedex seems to allow maximum three days ahead for the Pickup request
            break day.to_s if day.cwday < 6   # Ensuring its not Sat or Sun
          end,
          company_close_time: "16:00:00",
          remarks: "TEST PICKUP REQUEST, DO NOT PROCESS"
        }
      end

      it "succeeds" do
        expect {
          @pickup_request = fedex.pickup(options)
        }.to_not raise_error

        expect(@pickup_request.class).not_to eq(Fedex::FedexError)
      end
    end
  end
end
