require "test_helper"
require "securerandom"
require "cgi"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def auth_hash_for(uid: "U#{SecureRandom.hex(4)}", name: "Hack Club User", verification_status: "verified", ysws_eligible: true)
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

  test "login hands off to omniauth via a CSRF-protected POST form" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url

    assert_response :success
    # A redirect would be a GET, which omniauth no longer accepts; the handoff has to
    # be a form so the request phase carries an authenticity token.
    assert_select "form#oauth-handoff[action=?][method=?]", "/auth/hackclub", "post"
  end

  test "handoff page does not load the app layout or turbo" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    get login_url

    assert_response :success
    # The request phase answers with a 302 to auth.hackclub.com. Under Turbo that redirect
    # is fetch-followed, the cross-origin response carries no CORS headers, and the browser
    # shows Turbo's content-type-mismatch error instead of the Hack Club login. So this page
    # has to render without the layout (which is what pulls in Turbo) and the form has to opt
    # out, or clicking the fallback button dead-ends here.
    assert_no_match(/javascript_importmap_tags|@hotwired\/turbo/, response.body)
    assert_select "form#oauth-handoff[data-turbo=?]", "false"
    # The view is a whole document, so a layout would nest one <html> inside another.
    assert_equal 1, response.body.scan("<html").size
  end

  test "sign-in control on a page posts at the request phase from that page" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    with_forgery_protection do
      get about_path

      # No link to /login and no interstitial page: one click has to reach the provider from
      # the page it was clicked on, so the control is a form posting at the request phase.
      assert_select "a[href=?]", login_path, count: 0
      assert_select "form.oauth-handoff-form[action=?][method=?][data-turbo=?]",
                    "/auth/hackclub?origin=#{CGI.escape(about_path)}", "post", "false"
      assert_select "form.oauth-handoff-form input[name=authenticity_token]"

      token = css_select("form.oauth-handoff-form input[name=authenticity_token]").first&.[]("value")
      post "/auth/hackclub?origin=#{CGI.escape(about_path)}", params: { authenticity_token: token }

      assert_response :redirect
      assert_match(%r{\Ahttps://auth\.hackclub\.com/oauth/authorize}, response.location)
    end
  end

  test "omniauth request phase refuses a POST without a CSRF token" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    # OmniAuth routes the rejection through on_failure rather than raising, so the
    # signal is "we did not start a flow with the identity provider".
    post "/auth/hackclub"

    assert_redirected_to root_path
    assert_no_match(/auth\.hackclub\.com/, response.location.to_s)
  end

  test "omniauth request phase accepts the token the login form carries" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    with_forgery_protection do
      get login_url, params: { redirect: dashboard_path }

      token = css_select("form#oauth-handoff input[name=authenticity_token]").first&.[]("value")
      assert token.present?, "the handoff form has to carry a token for the request phase"

      post "/auth/hackclub?origin=#{CGI.escape(dashboard_path)}", params: { authenticity_token: token }

      # OmniAuth's own token scheme is gone, so the request phase has to accept the one Rails
      # issues. Before it did, every login died with "Attack prevented by
      # OmniAuth::AuthenticityTokenProtection" and bounced back to the home page.
      assert_response :redirect
      assert_match(%r{\Ahttps://auth\.hackclub\.com/oauth/authorize}, response.location)
    end
  end

  test "oauth callback is built from APP_URL rather than the request host" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"
    previous_app_url = ENV["APP_URL"]
    # Trailing slash included on purpose: APP_URL is written by hand and a doubled slash
    # would make redirect_uri differ from what is registered on the Hack Club app.
    ENV["APP_URL"] = "https://issued.hackclub.com/"

    with_forgery_protection do
      get login_url
      token = css_select("form#oauth-handoff input[name=authenticity_token]").first&.[]("value")
      post "/auth/hackclub", params: { authenticity_token: token }

      assert_response :redirect
      assert_match(%r{\Ahttps://auth\.hackclub\.com/oauth/authorize}, response.location)
      redirect_uri = Rack::Utils.parse_query(URI.parse(response.location).query)["redirect_uri"]
      # The provider compares this byte-for-byte and then sends the browser to it, so an
      # origin-only value comes back as the site root and login never completes.
      assert_equal "https://issued.hackclub.com/auth/hackclub/callback", redirect_uri
    end
  ensure
    ENV["APP_URL"] = previous_app_url
  end

  test "omniauth request phase refuses a token from another session" do
    ENV["HACKCLUB_CLIENT_ID"] = "test-client-id"
    ENV["HACKCLUB_CLIENT_SECRET"] = "test-client-secret"

    with_forgery_protection do
      get login_url
      token = css_select("meta[name=csrf-token]").first&.[]("content")
      assert token.present?

      reset! # the token is bound to the old session, so this POST arrives sessionless

      post "/auth/hackclub", params: { authenticity_token: token }

      assert_redirected_to root_path
      assert_no_match(/auth\.hackclub\.com/, response.location.to_s)
    end
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
    assert_equal "verified", user.veri_level
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
    assert_select "form#oauth-handoff[action=?]", "/auth/hackclub?origin=#{CGI.escape(dashboard_path)}"
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

  test "callback redirects to requested path when encryption keys are missing" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:hackclub] = auth_hash_for(uid: "U123")

    config = ActiveRecord::Encryption.config
    original_primary_key = config.instance_variable_get(:@primary_key)
    original_key_derivation_salt = config.instance_variable_get(:@key_derivation_salt)
    config.primary_key = nil
    config.key_derivation_salt = nil

    get "/auth/hackclub/callback", env: { "omniauth.origin" => dashboard_path }

    assert_redirected_to dashboard_path
    assert_not_nil session[:user_id]

  ensure
    config&.primary_key = original_primary_key
    config&.key_derivation_salt = original_key_derivation_salt
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
    user = User.create!(name: "x", slack_id: "U123", veri_level: :verified, ysws_eligible: false)
    sign_in_as(user)

    delete logout_url
    assert_redirected_to root_url
  end
end
