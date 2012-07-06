module Fedex
  class TrackingInformation
    class Event
      attr_reader :description, :type, :occured_at, :city, :state, :postal_code,
                  :country, :residential

      def initialize(details = {})
        @description  = details[:event_description]
        @type         = details[:event_type]
        @occured_at   = Time.parse(details[:timestamp])
        @city         = details[:address][:city]
        @state        = details[:address][:state_or_province_code]
        @postal_code  = details[:address][:postal_code]
        @country      = details[:address][:country_code]
        @residential  = details[:address][:residential] == "true"
      end
    end
  end
end