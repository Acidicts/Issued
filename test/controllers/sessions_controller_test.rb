require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login redirects to hackclub authorize" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url

    assert_redirected_to %r{https://auth.hackclub.com/oauth/authorize\?}, "Expected redirect to Hack Club OAuth authorize"
  end

  test "callback creates user and signs in" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    exchange_original = SessionsController.instance_method(:exchange_code_for_token)
    fetch_original = SessionsController.instance_method(:fetch_hackclub_me)

    SessionsController.define_method(:exchange_code_for_token) do |_code|
      { "access_token" => "fake-token", "refresh_token" => "fake-refresh" }
    end

    SessionsController.define_method(:fetch_hackclub_me) do |_token|
      { "slack_id" => "U123", "name" => "Hack Club User", "verification_status" => 1, "ysws_eligible" => true }
    end

    initial_user_count = User.count
    get hackclub_callback_url, params: { code: "abc123" }

    assert_redirected_to root_url
    assert_equal initial_user_count + 1, User.count
    user = User.order(created_at: :desc).first
    assert_equal "Hack Club User", user.name
    assert_equal "U123", user.slack_id
    assert_equal true, user.ysws_eligible

  ensure
    SessionsController.define_method(:exchange_code_for_token, exchange_original)
    SessionsController.define_method(:fetch_hackclub_me, fetch_original)
  end

  test "login stores redirect in session" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url, params: { redirect: dashboard_path }

    assert_equal dashboard_path, session[:return_to]
    assert_redirected_to %r{https://auth.hackclub.com/oauth/authorize\?}
  end

  test "callback redirects to requested path when provided" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    exchange_original = SessionsController.instance_method(:exchange_code_for_token)
    fetch_original = SessionsController.instance_method(:fetch_hackclub_me)

    SessionsController.define_method(:exchange_code_for_token) do |_code|
      { "access_token" => "fake-token", "refresh_token" => "fake-refresh" }
    end

    SessionsController.define_method(:fetch_hackclub_me) do |_token|
      { "slack_id" => "U123", "name" => "Hack Club User", "verification_status" => 1, "ysws_eligible" => true }
    end

    get hackclub_callback_url, params: { code: "abc123", redirect: dashboard_path }
    assert_redirected_to dashboard_path

  ensure
    SessionsController.define_method(:exchange_code_for_token, exchange_original)
    SessionsController.define_method(:fetch_hackclub_me, fetch_original)
  end

  test "callback handles missing code" do
    get hackclub_callback_url
    assert_redirected_to root_url
    assert_equal "Authorization code missing from Hack Club callback", flash[:alert]
  end

  test "destroy redirects to root" do
    user = User.create!(name: "x", slack_id: "U123", verified: 1)
    cookies[:user_id] = user.id
    delete logout_url
    assert_redirected_to root_url
  end
end
