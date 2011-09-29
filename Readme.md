# Fedex Rate Web Service

For more information visit [Fedex Web Services for Shipping](https://www.fedex.com/wpor/web/jsp/drclinks.jsp?links=wss/index.html).

This version uses the Non-SOAP Web Services so there is no need to download the Fedex WSDL files, note however that you will need to apply for 
development/production credentials.

Note: This is work in progress make sure to test your results.

# Installation:
    // Rails 3.x
    $ gem 'fedex'
    
    // Rails 2.x
    $ gem install fedex 

# Usage example:
   
Define the shipper:
                                     
    shipper = { :name => "Sender", 
                :company => "Company", 
                :phone_number => "555-555-5555", 
                :address => "Main Street", 
                :city => "Harrison", 
                :state => "AR", 
                :postal_code => "72601", 
                :country_code => "US" }

Define the recipient:    

    recipient = { :name => "Recipient", 
                    :company => "Company", 
                    :phone_number => "555-555-5555", 
                    :address => "Main Street", 
                    :city => "City", 
                    :state => "ST", 
                    :postal_code => "55555", 
                    :country_code => "US", 
                    :residential => "false" }
Define the packages(multiple packages in a single shipment are allowed):
                    
    packages = []
    packages << { :weight => {:units => "LB", :value => 2}, 
                   :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" } }
    packages << { :weight => {:units => "LB", :value => 6}, 
                   :dimensions => {:length => 5, :width => 5, :height => 4, :units => "IN" } }

By Default packaging type is "YOUR PACKAGING" and the drop off type is "REGULAR PICKUP", if you need something different you can pass an extra hash for shipping details

    shipping_details = { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }  
       
    
Create a Fedex::Shipment object, use your FedEx credentials; mode should be either production or development depending on what Fedex environment you want to use.
    require 'fedex'
    fedex = Fedex::Shipment.new(:key => 'xxx', 
                                  :password => 'xxxx', 
                                  :account_number => 'xxxx', 
                                  :meter => 'xxx', 
                                  :mode=>['production'|'development'])      

    rate = fedex.rate({:shipper=>shipper, :recipient => recipient, :packages => packages, :service_type => "FEDEX_GROUND", :shipping_details => shipping_details})    
    
Fedex provides multiple total values; total_net_charge is the final amount you are looking for. 
    $ rate.total_net_charge => "34.03"     
    
    # Complete response                              
    $ <Fedex::Rate:0x1019ba5f8 
          @total_net_charge="34.03", 
          @total_surcharges="1.93", 
          @total_billing_weight="8.0 LB", 
          @total_taxes="0.0",   
          @rate_type="PAYOR_ACCOUNT_PACKAGE", 
          @total_base_charge="32.1", 
          @total_freight_discounts=nil, 
          @total_net_freight="32.1", 
          @rate_zone="51"> 
       
           
# Services/Options Available

    Fedex::Shipment::SERVICE_TYPES
    Fedex::Shipment::PACKAGING_TYPES
    Fedex::Shipment::DROP_OFF_TYPES

# Copyright/License:
Copyright 2011 Jazmin Schroeder
This gem is made available under the MIT license

