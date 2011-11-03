require 'spec_helper'
describe Fedex::Shipment do
  let(:test_keys) do
    {:key => "xxxx", :password => "xxxx", :account_number => "xxxx", :meter => "xxxx", :mode => "test"} 
  end  
  
  let(:production_keys) do
    {:key => "xxxx", :password => "xxxx", :account_number => "xxxx", :meter => "xxxx", :mode => "production"} 
  end  
  
  context "missing required parameters" do
    it "should raise Fedex::Rate exception" do
      lambda{ Fedex::Shipment.new}.should raise_error(Fedex::RateError)
    end
  end
  
  context "required parameters present" do
    subject { Fedex::Shipment.new(test_keys) }
    it "should create a valid instance" do
      subject.should be_an_instance_of(Fedex::Shipment)
    end
  end
  
  context "Published Rates(Development Mode)" do
    before(:each) do
      @fedex = Fedex::Shipment.new(test_keys)
      @shipper = {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US"}
      @recipient = {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
      @packages = []
      @packages << { :weight => {:units => "LB", :value => 2}, 
                     :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" } }
      @packages << { :weight => {:units => "LB", :value => 6}, 
                     :dimensions => {:length => 5, :width => 5, :height => 4, :units => "IN" } }
      @shipping_options = { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }               
    end
  
    context "Domestic Shipment" do 
      describe "rate" do
        it "should return rate" do
          rate = @fedex.rate({:shipper=>@shipper, :recipient => @recipient, :packages => @packages, :service_type => "FEDEX_GROUND"})
          rate.should be_an_instance_of(Fedex::Rate)
          puts rate.total_net_charge
        
        end
      end
    end
  
    context "Canadian Shipment" do
      describe "rate" do
        it "shoule return international fees" do
          recipient = {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address=>"Address Line 1", :city => "Richmond", :state => "BC",
            :postal_code => "V7C4V4", :country_code => "CA", :residential => "true" }
          rate = @fedex.rate({:shipper => @shipper, :recipient => recipient, :packages => @packages, :service_type => "FEDEX_GROUND", :shipping_options => @shipping_options })
          rate.should be_an_instance_of(Fedex::Rate)
          puts rate.total_net_charge
        end
      end
    end  
  end
  
  context "Discounted Rates(Production Mode)" do
    before(:each) do
      @fedex = Fedex::Shipment.new(production_keys)
      @shipper = {:name => "Sender", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Harrison", :state => "AR", :postal_code => "72601", :country_code => "US"}
      @recipient = {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address => "Main Street", :city => "Frankin Park", :state => "IL", :postal_code => "60131", :country_code => "US", :residential => true }
      @packages = []
      @packages << { :weight => {:units => "LB", :value => 2}, 
                     :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" } }
      @packages << { :weight => {:units => "LB", :value => 6}, 
                     :dimensions => {:length => 5, :width => 5, :height => 4, :units => "IN" } }
      @shipping_options = { :packaging_type => "YOUR_PACKAGING", :drop_off_type => "REGULAR_PICKUP" }               
    end
  
    context "Domestic Shipment" do 
      describe "rate" do
        it "should return rate" do
          rate = @fedex.rate({:shipper=>@shipper, :recipient => @recipient, :packages => @packages, :service_type => "FEDEX_GROUND"})
          rate.should be_an_instance_of(Fedex::Rate)
          puts rate.total_net_charge
        
        end
      end
    end
  
    context "Canadian Shipment" do
      describe "rate" do
        it "shoule return international fees" do
          recipient = {:name => "Recipient", :company => "Company", :phone_number => "555-555-5555", :address=>"Address Line 1", :city => "Richmond", :state => "BC",
            :postal_code => "V7C4V4", :country_code => "CA", :residential => "true" }
          rate = @fedex.rate({:shipper => @shipper, :recipient => recipient, :packages => @packages, :service_type => "FEDEX_GROUND", :shipping_options => @shipping_options })
          rate.should be_an_instance_of(Fedex::Rate)
          puts rate.total_net_charge
        end
      end
    end  
  end

end
