require "test_helper"
require "securerandom"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def auth_hash_for(uid: "U#{SecureRandom.hex(4)}", name: "Hack Club User", verification_status: true, ysws_eligible: true)
    OmniAuth::AuthHash.new(
      provider: "hackclub",
      uid: uid,
      info: {
        name: name,
        slack_id: uid,
        verification_status: verification_status,
        ysws_eligible: ysws_eligible
      },
      credentials: {
        token: "fake-token",
        refresh_token: "fake-refresh"
      }
    )
  end

  test "login redirects to omniauth hackclub path" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url
    assert_redirected_to %r{/auth/hackclub}, "Expected redirect to OmniAuth hackclub path"
  end

  test "callback creates user and signs in" do
    initial_user_count = User.count

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = auth_hash_for(uid: "U123")
    get "/auth/hackclub/callback"

    assert_redirected_to root_url
    assert_equal initial_user_count + 1, User.count
    user = User.order(created_at: :desc).first
    assert_equal "Hack Club User", user.name
    assert_equal "U123", user.slack_id
    assert_equal true, user.ysws_eligible
    assert_equal 1, user.verified
    assert_equal user.id, session[:user_id]

  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:hackclub)
  end

  test "login stores redirect in session" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url, params: { redirect: dashboard_path }

    assert_equal dashboard_path, session[:return_to]
    assert_redirected_to %r{/auth/hackclub\?origin=}
  end

  test "callback redirects to requested path via omniauth origin" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = auth_hash_for(uid: "U123")
    get "/auth/hackclub/callback", env: { "omniauth.origin" => dashboard_path }

    assert_redirected_to dashboard_path

  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:hackclub)
  end

  test "callback handles missing auth hash" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = nil
    get "/auth/hackclub/callback"

    assert_redirected_to root_url

  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:hackclub)
  end

  test "destroy redirects to root" do
    user = User.create!(name: "x", slack_id: "U123", verified: true, ysws_eligible: false)
    sign_in_as(user)

    delete logout_url
    assert_redirected_to root_url
  end
end
