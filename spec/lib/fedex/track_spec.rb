require 'spec_helper'

module Fedex
  describe TrackingInformation do
    let(:fedex) { Shipment.new(fedex_credentials) }

    context "shipments with tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => "077973360403984",
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end

      it "returns events with tracking information" do
        tracking_info = fedex.track(options)

        tracking_info.events.count.should == 7
      end

      it "fails if using an invalid package type" do
        fail_options = options

        fail_options[:package_type] = "UNKNOWN_PACKAGE"

        lambda { fedex.track(options) }.should raise_error
      end

      it "allows short hand tracking number queries" do
        shorthand_options = options

        shorthand_options.delete(:package_type)
        tracking_number = shorthand_options.delete(:package_id)

        shorthand_options[:tracking_number] = tracking_number

        tracking_info = fedex.track(shorthand_options)

        tracking_info.tracking_number.should == tracking_number
      end

      it "reports the status of the package" do
        tracking_info = fedex.track(options)

        tracking_info.status.should == "Delivered"
      end

    end
  end
end