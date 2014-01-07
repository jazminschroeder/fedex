
module Fedex
  class PendingShipmentLabel
    attr_accessor :email_label_url
    def initialize(label_details = {})
      @email_label_url = label_details[:completed_shipment_detail][:access_detail][:email_label_url]
    end


  end
end