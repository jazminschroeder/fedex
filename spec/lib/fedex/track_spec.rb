require 'spec_helper'

module Fedex
  describe TrackingInformation do
    let(:fedex) { Shipment.new(fedex_credentials) }

    context "shipments with tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => "123456789012",
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end

      let(:uuid) { fedex.track(options).first.unique_tracking_number }

      it "returns an array of tracking information results" do
        results = fedex.track(options)
        results.should_not be_empty
      end

      it "returns events with tracking information" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        tracking_info.events.should_not be_empty
      end

      it "fails if using an invalid package type" do
        fail_options = options

        fail_options[:package_type] = "UNKNOWN_PACKAGE"

        lambda { fedex.track(options) }.should raise_error
      end

      it "allows short hand tracking number queries" do
        shorthand_options = { :tracking_number => options[:package_id] }

        tracking_info = fedex.track(shorthand_options).first

        tracking_info.tracking_number.should == options[:package_id]
      end

      it "reports the status of the package" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        tracking_info.status.should_not be_nil
      end

    end
  end
end
