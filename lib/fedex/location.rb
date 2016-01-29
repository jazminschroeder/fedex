require 'fedex/location_address'

module Fedex
     class Location
          attr_accessor :address, :geographic_coordinates, :latitude, :longitude, :normal_hours

          def initialize(location_detail = {})
            raise ArgumentError, "Location detail is nil or empty" if location_detail.nil? || location_detail.empty?
            @address = Fedex::LocationAddress.new(location_detail[:location_contact_and_address])
            @location_id = location_detail[:location_id]
            if !!(s = splitGeographicCoordinates(location_detail[:geographic_coordinates].chop))
                 @latitude = s[0] + s[1]
                 @longitude = s[2] + s[3]
            end
            @normal_hours = location_detail[:normal_hours]
          end

          private

          def splitGeographicCoordinates(coords)
               a = coords.split /(\s|\+|\-)/
               if a.size == 5
                    a.drop(1)
               else
                    nil
               end
          end
     end
end
