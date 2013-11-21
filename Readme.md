# Fedex Rate Web Service


For more information visit [Fedex Web Services for Shipping](https://www.fedex.com/wpor/web/jsp/drclinks.jsp?links=wss/index.html).

This version uses the Non-SOAP Web Services so there is no need to download the
Fedex WSDL files, note however that you will need to apply for development/production credentials.

Note: Please make sure to test your results.


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
If you need something different you can pass an extra hash for shipping options

```ruby
shipping_options = {
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
                  :shipping_options => shipping_options)
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
### ** Get a Transit time **
```ruby
ship = fedex.ship(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_options => shipping_options)
puts ship[:completed_shipment_detail][:operational_detail] [:transit_time]
```
Above code will give you the transit time.

### ** Generate a shipping label (PDF) **

To create a label for a shipment:

```ruby
label = fedex.label(:filename => "my_dir/example.pdf",
                    :shipper=>shipper,
                    :recipient => recipient,
                    :packages => packages,
                    :service_type => "FEDEX_GROUND",
                    :shipping_options => shipping_options)
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
                    :shipping_options => shipping_options,
                    :label_specification => example_spec)
```
### ** Storing a label on Amazon S3 with Paperclip **

This is useful when you need to store the labels for later use, and are hosting your application on [Heroku](http://www.heroku.com/) as they do not allow writing to the filesystem, save the `tmp` directory. With [Paperclip](https://github.com/thoughtbot/paperclip/) setup up on a shipment model:

```ruby
label = fedex.label(:filename => "tmp/example_label.pdf",
                    :shipper=>shipper,
                    :recipient => recipient,
                    :packages => packages,
                    :service_type => "FEDEX_GROUND",
                    :shipping_options => shipping_options,
                    :label_specification => example_spec)
```

Then attach the label to your Paperclip model:

```ruby
shipment.fedex_label = label.file_name
shipment.save!
```

Documentation for setting up Paperclip with Amazon S3 can be found in the Paperclip [README](https://github.com/thoughtbot/paperclip/#storage).


### ** Tracking a shipment **

To track a shipment:

```ruby
results = fedex.track(:tracking_number => "1234567890123")
# => [#<Fedex::TrackingInformation>]

# Pull the first result from the returned array
#
tracking_info = results.first

tracking_info.tracking_number
# => "1234567890123"

tracking_info.status
# => "Delivered"

tracking_info.events.first.description
# => "On FedEx vehicle for delivery"
```

### ** Verifying an address **

To verify an address is valid and deliverable:

```ruby

address = {
  :street      => "5 Elm Street",
  :city        => "Norwalk",
  :state       => "CT",
  :postal_code => "06850",
  :country     => "USA"
}

address_result = fedex.validate_address(:address => address)

address_result.residential
# => true

address_result.score
# => 100

address_result.postal_code
# => "06850-3901"
```

# Services/Options Available

```ruby
Fedex::Shipment::SERVICE_TYPES
Fedex::Shipment::PACKAGING_TYPES
Fedex::Shipment::DROP_OFF_TYPES
````

# Contributors:
- [jazminschroeder] (http://github.com/jazminschroeder) (Jazmin Schroeder)
- [parndt] (https://github.com/parndt) (Philip Arndt)
- [mmell] (https://github.com/mmell) (Michael Mell)
- [jordanbyron] (https://github.com/jordanbyron) (Jordan Byron)
- [geermc4] (https://github.com/geermc4) (German Garcia)
- [janders223] (https://github.com/janders223) (Jim Anders)
- [jlambert121] (https://github.com/jlambert121) (Justin Lambert)
- [sborsje] (https://github.com/sborsje) (Stefan Borsje)
- [bradediger] (https://github.com/bradediger) (Brad Ediger)
- [yevgenko] (https://github.com/yevgenko) (Yevgeniy Viktorov)
- [smartacus] (https://github.com/smartacus) (Michael Lippold)
- [jonathandean] (https://github.com/jonathandean) (Jonathan Dean)

# Copyright/License:
Copyright 2011 [Jazmin Schroeder](http://jazminschroeder.com)

This gem is made available under the MIT license.
