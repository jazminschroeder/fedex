require 'fedex/location_address'

module Fedex
	class Location
		attr_accessor :address, :geographic_coordinates, :latitude, :longitude, :normal_hours

		def initialize(options = {})
			options[:distance_and_location_details][:location_detail].tap do |location_detail| 				
				@address = Fedex::LocationAddress.new(location_detail[:location_contact_and_address])	
				if !!(s = splitGeographicCoordinates(location_detail[:geographic_coordinates].chop)) 
					@latitude = s[0]
					@longitude = s[1]
				end
				@normal_hours = location_detail[:normal_hours]
			end
		end

		private

		def splitGeographicCoordinates(coords)
			a = coords.split /\s|\+|\-/
			if a.size == 3
				a.drop(1)
			else 
				nil
			end
		end
	end
end

     # "MatchedAddress": {
     #    "City": "SF",
     #    "StateOrProvinceCode": "CA",
     #    "PostalCode": "94109",
     #    "CountryCode": "US",
     #    "Residential": "false"
     #  },
     #  "MatchedAddressGeographicCoordinates": "+37.7929789-122.4212424/",
     #  "DistanceAndLocationDetails": {
     #    "Distance": {
     #      "Value": "0.679",
     #      "Units": "KM"
     #    },
     #    "LocationDetail": {
     #      "LocationId": "SFOKO",
     #      "StoreNumber": "0",
     #      "LocationContactAndAddress": {
     #        "Contact": {
     #          "CompanyName": "FedEx Office Print & Ship Center",
     #          "PhoneNumber": "(415) 292-2500",
     #          "FaxNumber": "(415) 292-2504",
     #          "EMailAddress": "USA0289@FEDEX.COM"
     #        },
     #        "Address": {
     #          "StreetLines": "1 Daniel Burnham Court",
     #          "City": "San Francisco",
     #          "StateOrProvinceCode": "CA",
     #          "PostalCode": "94109",
     #          "CountryCode": "US",
     #          "Residential": "false"
     #        },
     #        "AddressAncillaryDetail": {
     #          "Suite": "10c",
     #          "AdditionalDescriptions": "FedEx Office Print & Ship Center"
     #        }
     #      },
     #      "GeographicCoordinates": "+37.787-122.42255/",
     #      "LocationType": "FEDEX_OFFICE",
     #      "Attributes": [
     #        "SATURDAY_DROPOFFS",
     #        "WEEKDAY_EXPRESS_HOLD_AT_LOCATION",
     #        "SATURDAY_EXPRESS_HOLD_AT_LOCATION",
     #        "GROUND_DROPOFFS",
     #        "ACCEPTS_CASH",
     #        "PACK_AND_SHIP",
     #        "PACKAGING_SUPPLIES",
     #        "RETURNS_SERVICES",
     #        "SIGNS_AND_BANNERS_SERVICE",
     #        "SONY_PICTURE_STATION",
     #        "DIRECT_MAIL_SERVICES",
     #        "ALREADY_OPEN",
     #        "WEEKDAY_GROUND_HOLD_AT_LOCATION",
     #        "COPY_AND_PRINT_SERVICES",
     #        "EXPRESS_PARCEL_DROPOFFS"
     #      ],
     #      "MapUrl": "https://maps.googleapis.com/maps/api/staticmap?size=350x350&center=+37.787,-122.42255&zoom=15&markers=color:blue%7Clabel:A%7C1+Daniel+Burnham+Court%2CSan+Francisco%2CCA%2C94109&maptype=roadmap&sensor=false",
     #      "NormalHours": [
