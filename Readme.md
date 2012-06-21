# Fedex Rate Web Service

For more information visit [Fedex Web Services for Shipping](https://www.fedex.com/wpor/web/jsp/drclinks.jsp?links=wss/index.html).

This version uses the Non-SOAP Web Services so there is no need to download the
Fedex WSDL files, note however that you will need to apply for development/production credentials.

Note: This is work in progress make sure to test your results.

# Installation:

Rails 3.x using Bundler's Gemfile:

```ruby
gem 'fedex'
````

Rails 2.x or without Rails or Bundler:

```ruby
gem install fedex
```

# Usage example:

Define the shipper:

```ruby
shipper = { :name => "Sender",
            :company => "Company",
            :phone_number => "555-555-5555",
            :address => "Main Street",
            :city => "Harrison",
            :state => "AR",
            :postal_code => "72601",
            :country_code => "US" }
```

Define the recipient:

```ruby
recipient = { :name => "Recipient",
              :company => "Company",
              :phone_number => "555-555-5555",
              :address => "Main Street",
              :city => "Franklin Park",
              :state => "IL",
              :postal_code => "60131",
              :country_code => "US",
              :residential => "false" }
```

Define the packages; multiple packages in a single shipment are allowed:
Note that all the dimensions must be integers.

```ruby
packages = []
packages << {
  :weight => {:units => "LB", :value => 2},
  :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
}
packages << {
  :weight => {:units => "LB", :value => 6},
  :dimensions => {:length => 5, :width => 5, :height => 4, :units => "IN" }
}
```

By default packaging type is "YOUR PACKAGING" and the drop off type is "REGULAR PICKUP".
If you need something different you can pass an extra hash for shipping details

```ruby
shipping_details = {
  :packaging_type => "YOUR_PACKAGING",
  :drop_off_type => "REGULAR_PICKUP"
}
```

Create a `Fedex::Shipment` object using your FedEx credentials; mode should be
either production or development depending on what Fedex environment you want to use.

```ruby
require 'fedex'
fedex = Fedex::Shipment.new(:key => 'xxx',
                            :password => 'xxxx',
                            :account_number => 'xxxx',
                            :meter => 'xxx',
                            :mode => 'production')
```

### ** Getting Shipping Rates **

To find a shipping rate:

```ruby
rate = fedex.rate(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_details => shipping_details)
```

Fedex provides multiple total values; `total_net_charge` is the final amount you are looking for.

```ruby
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
```

### ** Generate a shipping label(PDF) **

To create a label for a shipment:

```ruby
label = fedex.label(:filename => "my_dir/example.pdf",
                    :shipper=>shipper,
                    :recipient => recipient,
                    :packages => packages,
                    :service_type => "FEDEX_GROUND",
                    :shipping_details => shipping_details)
```

### ** Generate a shipping label in any available format **

Change the filename extension and pass a label_specification hash. For example:

```ruby
example_spec = {
  :image_type => "EPL2",
  :label_stock_type => "STOCK_4X6"
}

label = fedex.label(:filename => "my_dir/example_epl2.pcx",
                    :shipper=>shipper,
                    :recipient => recipient,
                    :packages => packages,
                    :service_type => "FEDEX_GROUND",
                    :shipping_details => shipping_details,
                    :label_specification => example_spec)
```

# Services/Options Available

```ruby
Fedex::Shipment::SERVICE_TYPES
Fedex::Shipment::PACKAGING_TYPES
Fedex::Shipment::DROP_OFF_TYPES
````

# Contributors:
- [jazminschroeder](http://github.com/jazminschroeder) (Jazmin Schroeder)
- [parndt](https://github.com/parndt) (Philip Arndt)

# Copyright/License:
Copyright 2011 [Jazmin Schroeder](http://jazminschroeder.com)

This gem is made available under the MIT license.
