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

      context "multiple address validation results", :vcr do
        let(:address) do
          {
            :street      => "301 Las Colinas Blvd",
            :city        => "Irving",
            :state       => "TX",
            :postal_code => "75039",
            :country     => "USA"
          }
        end

        let(:options) do
          { :address => address }
        end

        it "validates the address" do
          expect{ fedex.validate_address(options) }.to_not raise_error
        end
      end

    end
  end
end