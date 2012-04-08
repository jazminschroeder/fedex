require 'fedex/helpers'

module Fedex
  class Credentials
    include Helpers
    attr_reader :key, :password, :account_number, :meter, :mode

    # In order to use Fedex rates API you must first apply for a developer(and later production keys),
    # Visit {http://www.fedex.com/us/developer/ Fedex Developer Center} for more information about how to obtain your keys.
    # @param [String] key - Fedex web service key
    # @param [String] password - Fedex password
    # @param [String] account_number - Fedex account_number
    # @param [String] meter - Fedex meter number
    # @param [String] mode - [development/production]
    #
    # return a Fedex::Credentials object
    def initialize(options={})
      requires!(options, :key, :password, :account_number, :meter, :mode)
      @key = options[:key]
      @password = options[:password]
      @account_number = options[:account_number]
      @meter = options[:meter]
      @mode = options[:mode]
    end
  end
end