require 'spec_helper'

module Fedex
  describe TrackingInformation do
    let(:fedex) { Shipment.new(fedex_credentials) }

    context "shipments with tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => "771513950417",
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end

      let(:uuid) { fedex.track(options).first.unique_tracking_number }

      it "returns an array of tracking information results" do
        results = fedex.track(options)
        expect(results).not_to be_empty
      end

      it "returns events with tracking information" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        expect(tracking_info.events).not_to be_empty
      end

      it "fails if using an invalid package type" do
        fail_options = options

        fail_options[:package_type] = "UNKNOWN_PACKAGE"

        expect { fedex.track(options) }.to raise_error
      end

      it "allows short hand tracking number queries" do
        shorthand_options = { :tracking_number => options[:package_id] }

        tracking_info = fedex.track(shorthand_options).first

        expect(tracking_info.tracking_number).to eq(options[:package_id])
      end

      it "reports the status of the package" do
        tracking_info = fedex.track(options.merge(:uuid => uuid)).first

        expect(tracking_info.status).not_to be_nil
      end

    end

    context "duplicate shipments with same tracking number", :vcr, :focus do
      let(:options) do
        { :package_id             => "771054010426",
          :package_type           => "TRACKING_NUMBER_OR_DOORTAG",
          :include_detailed_scans => true
        }
      end

      it "should return tracking information for all shipments associated with tracking number" do
        tracking_info = fedex.track(options)

        expect(tracking_info.length).to be > 1
      end
    end
  end
end
