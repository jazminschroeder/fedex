module Fedex
  # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for a complete list of values returned from the API
  #
  # Rate totals are contained in the node
  #    response[:rate_reply][:rate_reply_details][:rated_shipment_details]
  class Rate
    attr_accessor :service_type, :transit_time, :rate_type, :rate_zone, :total_billing_weight, :total_freight_discounts, :total_net_charge, :total_taxes, :total_net_freight, :total_surcharges, :total_base_charge, :data

    # Initialize Fedex::Rate Object
    # @param [Hash] options
    #
    #
    # return [Fedex::Rate Object]
    #     @rate_type #Type used for this specific set of rate data
    #     @rate_zone #Indicates the rate zone used(based on origin and destination)
    #     @total_billing_weight #The weight used to calculate these rates
    #     @total_freight_discounts #The toal discounts used in the rate calculation
    #     @total_net_charge #The net charge after applying all discounts and surcharges
    #     @total_taxes #Total of the transportation-based taxes
    #     @total_net_freight #The freight charge minus dicounts
    #     @total_surcharges #The total amount of all surcharges applied to this shipment
    #     @total_base_charge #The total base charge
    def initialize(options = {})
      @data = options
      @service_type = options[:service_type]
      @transit_time = options[:transit_time]
      rate_details = [options[:rated_shipment_details]].flatten.first[:shipment_rate_detail]
      @rate_type = rate_details[:rate_type]
      @rate_zone = rate_details[:rate_zone]
      @total_billing_weight = "#{rate_details[:total_billing_weight][:value]} #{rate_details[:total_billing_weight][:units]}"
      @total_freight_discounts = rate_details[:total_freight_discounts]
      @total_net_charge = rate_details[:total_net_charge][:amount]
      @total_taxes = rate_details[:total_taxes][:amount]
      @total_net_freight = rate_details[:total_net_freight][:amount]
      @total_surcharges = rate_details[:total_surcharges][:amount]
      @total_base_charge = rate_details[:total_base_charge][:amount]
      @total_net_fedex_charge = (rate_details[:total_net_fe_dex_charge]||{})[:amount]
      @total_rebates = (rate_details[:total_rebates]||{})[:amount]
    end

    def [](key)
      @data[key]
    end
  end
end
