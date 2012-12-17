# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fedex/version"

Gem::Specification.new do |s|
  s.name        = "fedex"
  s.version     = Fedex::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jazmin Schroeder"]
  s.email       = ["jazminschroeder@gmail.com"]
  s.homepage    = "https://github.com/jazminschroeder/fedex"
  s.summary     = %q{Fedex Web Services}
  s.description = %q{Provides an interface to Fedex Web Services(version 10) - shipping rates, generate labels and address validation}

  s.rubyforge_project = "fedex"

  s.add_dependency 'httparty',            '~> 0.9.0'
  s.add_dependency 'nokogiri',            '~> 1.5.0'

  s.add_development_dependency "rspec",   '~> 2.9.0'
  s.add_development_dependency 'vcr',     '~> 2.0.0'
  s.add_development_dependency 'fakeweb'
  # s.add_runtime_dependency "rest-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


end
