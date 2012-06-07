require 'spec_helper'

module Fedex
  describe Address, :production do
    describe "validation" do

      # Address Validation is only enabled in the production environment
      #
      let(:fedex) { Shipment.new(fedex_production_credentials) }

      context "valid address", :vcr do
        let(:address) do
          {
            :street      => "5 Elm Street",
            :city        => "Norwalk",
            :state       => "CT",
            :postal_code => "06850",
            :country     => "USA"
          }
        end

        let(:options) do
          { :address => address }
        end

        it "validates the address" do
          address = fedex.validate_address(options)

          address.residential.should be_true
          address.business.should    be_false
          address.score.should ==    100

          address.postal_code.should == "06850-3901"
        end
      end

    end
  end
end