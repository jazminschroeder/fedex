# IMPORTANT!!
I plan a major refactor to this gem. Sorry but at this moment I am not merging PR's. I appreciate your effort but need some time to catch up. Thanks!! 

# Fedex Rate Web Service
## Fedex API Shipment Version: 13

For more information visit [Fedex Web Services for Shipping](https://www.fedex.com/wpor/web/jsp/drclinks.jsp?links=wss/index.html).

This version uses the Non-SOAP Web Services so there is no need to download the
Fedex WSDL files, note however that you will need to apply for development/production credentials.

Note: Please make sure to test your results.


# Installation:

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
If you need something different you can pass an extra hash for shipping options.

```ruby
shipping_options = {
  :packaging_type => "YOUR_PACKAGING",
  :drop_off_type => "REGULAR_PICKUP"
}
```

If you pass a non-nil `:return_reason` as part of the shipping options, you will create
a return shipment. The request to fedex will include the following additional XML.

```xml
<SpecialServicesRequested>
  <SpecialServiceTypes>RETURN_SHIPMENT</SpecialServiceTypes>
  <ReturnShipmentDetail>
    <ReturnType>PRINT_RETURN_LABEL</ReturnType>
    <Rma>
      <Reason>YOUR RETURN REASON HERE</Reason>
    </Rma>
  </ReturnShipmentDetail>
</SpecialServicesRequested>
```

By default the shipping charges will be assigned to the sender. If you may
change this by passing an extra hash of payment options.

```ruby
payment_options = {
  :type => "THIRD_PARTY",
  :account_number => "123456789",
  :name => "Third Party Payor",
  :company => "Company",
  :phone_number => "555-555-5555",
  :country_code => "US"
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
### ** Create a shipment and Get a Transit time(please note this will generate a shipment in your Fedex account if you are using production mode) **
```ruby
ship = fedex.ship(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_options => shipping_options)
puts ship[:completed_shipment_detail][:operational_detail][:transit_time]
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

### ** Generate shipping labels for multi-package shipments (MPS) **

Multiple packages for a single pick-up, destination and payer can be combined into a single MPS shipment. The first label will provide a master tracking number which must be used in the subsequent calls for the remaining packages in the shipment.

Parameters for the first label:
```ruby
label = fedex.label(
  :filename => file_name,
  :shipper => shipper,
  :recipient => recipient,
  :packages => packages,
  :service_type => service_type,
  :shipping_details => shipping_details,
  :shipping_charges_payment => shipping_charges_payment,
  :customs_clearance_detail => customs_clearance_detail,
  :mps => {:package_count => package_count, :total_weight => total_weight, :sequence_number => '1'}
  )
```

Parameters for labels 2 through 'n':
```ruby
fedex.label(
  :filename => file_name,
  :shipper => shipper,
  :recipient => recipient,
  :packages => packages,
  :service_type => service_type,
  :shipping_details => shipping_details,
  :shipping_charges_payment => shipping_charges_payment,
  :customs_clearance_detail => customs_clearance_detail,
  :mps => {
      :master_tracking_id => {:tracking_id_type => 'FEDEX', :tracking_number =>tracking_number},
      :package_count => package_count,
      :total_weight => {
          :value => total_weight,
          :units => 'KG'
      }
      :sequence_number => 'n'
      }
   )
```

### ** Create COD Shipment **

To create a Cash On Delivery label for a shipment:

change "commerical_invoice = {:purpose => 'SOLD'}" in customs_clearance_detail

add shipping_options with {:cod => {:currency => "currency", :amount => "amount", :collection_type => 'PAYMENT COLLECTION TYPE'}

PAYMENT COLLECTION TYPE - CASH, CHEQUE, DEMAND DRAFT

### ** To add multiple commodities in customs_clearance_detail

use this format commodities_1 .... commodities_N

example 

```

customs_clearance_detail['commodites_1'] 
customs_clearance_detail['commodites_2']

```

### ** Masking shipper details in label **

this allows you hide shipper details on the label

Add customer_specified_detail = {:masked_data_1 => 'SOMETHING', :masked_data_2 => 'SOMETHING'} in :label_specification key

Example

```
  customer_specified_detail = {
      :masked_data_1 => "SHIPPER_ACCOUNT_NUMBER",
      :masked_data_2 => "TRANSPORTATION_CHARGES_PAYOR_ACCOUNT_NUMBER",
      :masked_data_3 => "DUTIES_AND_TAXES_PAYOR_ACCOUNT_NUMBER"
  }

```

### ** Delete a shipment **

If you do not intend to use a label you should delete it. This will notify FedEx that you will not be using the label and they won't charge you. 

To delete a shipment:

```ruby
fedex.delete(:tracking_number => "1234567890123")
```

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
  :street     => "5 Elm Street",
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

### ** Requesting a Pickup **

To request a pickup:

```ruby

pickup = fedex.pickup(:carrier_code => 'FDXE',
                      :packages => {:weight => {:units => "LB", :value => 10}, :count => 2},
                      :ready_timestamp => Date.today.to_datetime + 1.375,
                      :close_time => Date.today.to_time + 60 * 60 * 17,
                      :country_relationship => "DOMESTIC")
puts pickup[:pickup_confirmation_number]
```

### ** Getting pickup availability details **

To check for pickup availability:

```ruby

dispatch = Date.tomorrow.strftime('%Y-%m-%d')

pickup_availability = fedex.pickup_availability(:country_code => 'IN',
                                   :postal_code => '400061',
                                   :request_type => 'FUTURE_DAY',
                                   :dispatch_date => dispatch_date,
                                   :carrier_code => 'FDXE')

puts pickup_availability[:options]
```

### ** Getting service availability **

To check service availability:

```ruby

origin = {:postal_code => '400012', :country_code => 'IN'}
destination = { :postal_code => '400020', :country_code => 'IN'}
fedex_service_hash = {:origin => origin, :destination => destination, :ship_date => '2014-06-28', :carrier_code => 'FDXE'}

service = fedex.service_availability(fedex_service_hash)

puts service[:options]
```

# Services/Options Available

```ruby
Fedex::Request::Base::SERVICE_TYPES
Fedex::Request::Base::PACKAGING_TYPES
Fedex::Request::Base::DROP_OFF_TYPES
Fedex::Request::Base::CARRIER_CODES
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
- [chirag7jain] (https://github.com/chirag7jain) (Chirag Jain)
- and more... (https://github.com/jazminschroeder/fedex/graphs/contributors)

# Copyright/License:
Copyright 2011 [Jazmin Schroeder](http://jazminschroeder.com)

This gem is made available under the MIT license.
