# frozen_string_literal: true

def fedex_development_credentials
  @fedex_development_credentials ||= {
    key: ENV.fetch('FEDEX_TEST_KEY', 'TEST_KEY'),
    password: ENV.fetch('FEDEX_TEST_PASSWORD', 'TEST_PASSWORD'),
    account_number: ENV.fetch('FEDEX_TEST_ACCOUNT_NUMBER', 'TEST_ACCOUNT_NUMBER'),
    meter: ENV.fetch('FEDEX_TEST_METER', 'TEST_METER'),
    mode: 'test'
  }
end
