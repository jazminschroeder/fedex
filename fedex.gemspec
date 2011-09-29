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
  s.summary     = %q{Fedex Rate Webservice}
  s.description = %q{Ruby Library to use Fedex Web Services(version 10)}

  s.rubyforge_project = "fedex"
  s.add_development_dependency "rspec"
  s.add_dependency 'httparty'
  s.add_dependency 'nokogiri'
  # s.add_runtime_dependency "rest-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  
end
