ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # The notification model is namespaced, so `notifications`.camelize resolves to the
    # `Notifications` module instead of an ActiveRecord class and Rails cannot infer the
    # fixture's model class. Without it the `user:` labels are never turned into
    # foreign keys and the insert fails on an unknown `user` column.
    set_fixture_class notifications: "Notifications::Notification"

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: user.slack_id,
      info: {
        name: user.name,
        slack_id: user.slack_id,
        verification_status: user.veri_level.to_s,
        ysws_eligible: user.ysws_eligible
      }
    )

    get "/auth/hackclub/callback"
  ensure
    OmniAuth.config.mock_auth.delete(:hackclub)
    OmniAuth.config.test_mode = false
  end
end
