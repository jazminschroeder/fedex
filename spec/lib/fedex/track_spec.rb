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

      let(:uuid) { "12012~123456789012~FDEG" }

      it "returns an array of tracking information results" do
        results = fedex.track(options)

        results.length.should == 9
      end

      it "returns events with tracking information" do
        options[:uuid] = uuid

        tracking_info = fedex.track(options).first

        tracking_info.events.count.should == 52
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
        options[:uuid] = uuid

        tracking_info = fedex.track(options).first

        tracking_info.status.should == "In transit"
      end

    end
  end
end