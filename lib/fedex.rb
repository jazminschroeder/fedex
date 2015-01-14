require 'fedex/shipment'

# Get shipping rates trough Fedex Web Services
#
# In order to use the API you will need to apply for developer/production credentials,
# Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
#
# ===Usage example
#    #Use your own Fedex Keys
#    fedex = Fedex::Shipment.new(:key => 'xxx',
#                               :password => 'xxxx',
#                               :account_number => 'xxxx',
#                               :meter => 'xxx',
#                               :mode=>['production'|'development'])
#    shipper = {:name => "Sender",
#               :company => "Company",
#               :phone_number => "555-555-5555",
#               :address => "Main Street",
#               :city => "Harrison",
#               :state => "AR",
#               :postal_code => "72601",
#               :country_code => "US" }
#
#    recipient = { :name => "Recipient",
#                  :company => "Company",
#                  :phone_number => "555-555-5555",
#                  :address => "Main Street",
#                  :city => "City",
#                  :state => "ST",
#                  :postal_code => "55555",
#                  :country_code => "US",
#                  :residential => "false" }
#    packages = []
#    packages << { :weight => {:units => "LB", :value => 2},
#                 :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" } }
#    packages << { :weight => {:units => "LB", :value => 6},
#                 :dimensions => {:length => 5, :width => 5, :height => 4, :units => "IN" } }
#    # "YOUR PACKAGING" and "REGULAR PICKUP" are the default options for all shipments but you can easily change them by passing an extra hash for #    shipping_options
#    shipping_options = { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }
#    rate = fedex.rate({:shipper=>shipper, :recipient => recipient, :packages => packages, :service_type => "FEDEX_GROUND", :shipping_options => #shipping_options})
#
#    $ <Fedex::Rate:0x1019ba5f8 @total_net_charge="34.03",
#        @total_surcharges="1.93",
#        @total_billing_weight="8.0 LB",
#        @total_taxes="0.0",
#        @rate_type="PAYOR_ACCOUNT_PACKAGE",
#        @total_base_charge="32.1",
#        @total_freight_discounts=nil,
#        @total_net_freight="32.1",
#        @rate_zone="51">
module Fedex
  require 'fedex/version'
  #Exceptions: Fedex::RateError
  class RateError < StandardError
    attr_accessor :code

    def initialize(msg = nil, code: nil)
      super(msg)
      @code = code
    end
  end
end
