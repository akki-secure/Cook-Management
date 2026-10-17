ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 2)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelper
  def sign_in_as(user, password: 'password123')
    post login_url, params: { email: user.email, password: password }
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include SignInHelper }
