# -*- encoding: utf-8 -*-
# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'fedex/version'

Gem::Specification.new do |s|
  s.name        = 'fedex'
  s.version     = Fedex::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Jazmin Schroeder']
  s.email       = ['jazminschroeder@gmail.com']
  s.homepage    = 'https://github.com/jazminschroeder/fedex'
  s.summary     = 'Fedex Web Services'
  s.description = 'Provides an interface to Fedex Web Services'

  s.rubyforge_project = 'fedex'

  s.license = 'MIT'

  s.add_dependency 'httparty',            '>= 0.14.0'
  s.add_dependency 'nokogiri',            '>= 1.5.6'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec',   '~> 3.8'
  s.add_development_dependency 'vcr',     '~> 5.0'
  s.add_development_dependency 'webmock', '~> 3.6'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
