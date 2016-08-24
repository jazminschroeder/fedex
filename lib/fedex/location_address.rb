module Fedex
	class LocationAddress

		attr_reader :street_lines, :city, :postal_code, :country_code, :residential, :name

		def initialize(options = {})
		    options[:address].tap do |address|
		    	@street_lines	= address[:street_lines]
		    	@city 			= address[:city]
			    @postal_code  	= address[:postal_code]
			    @country_code	= address[:country_code]
			    @residential 	= address[:residential]
			end
		end
	end
end
