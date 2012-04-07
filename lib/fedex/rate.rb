module Fedex
  # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for a complete list of values returned from the API
  #
  # Rate totals are contained in the node
  #    response[:rate_reply][:rate_reply_details][:rated_shipment_details]
  class Rate
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
    attr_accessor :rate_type, :rate_zone, :total_bilint_weight, :total_freight_discounts, :total_net_charge, :total_taxes, :total_net_freight, :total_surcharges, :total_base_charge
    def initialize(options = {})
      @rate_type = options[:rate_type]
      @rate_zone = options[:rate_zone]
      @total_billing_weight = "#{options[:total_billing_weight][:value]} #{options[:total_billing_weight][:units]}"
      @total_freight_discounts = options[:total_freight_discounts]
      @total_net_charge = options[:total_net_charge][:amount]
      @total_taxes = options[:total_taxes][:amount]
      @total_net_freight = options[:total_net_freight][:amount]
      @total_surcharges = options[:total_surcharges][:amount]
      @total_base_charge = options[:total_base_charge][:amount]
      @total_net_fedex_charge = (options[:total_net_fe_dex_charge]||{})[:amount]
      @total_rebates = (options[:total_rebates]||{})[:amount]
    end
  end
end