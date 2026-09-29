require "test_helper"

class CspCheckTest < ActionDispatch::IntegrationTest
  NONCE_RE = /'nonce-([^']+)'/.freeze

  test "policy is emitted with a non-empty nonce" do
    get root_path
    csp = response.headers["Content-Security-Policy"]

    assert csp.present?, "no CSP header"
    nonce = csp[NONCE_RE, 1]
    assert nonce.present?, "script-src nonce is empty: #{csp}"
    assert_operator nonce.length, :>=, 16
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'none'"
  end

  test "nonce differs between requests" do
    get root_path
    first = response.headers["Content-Security-Policy"][NONCE_RE, 1]
    get root_path
    second = response.headers["Content-Security-Policy"][NONCE_RE, 1]

    assert_not_equal first, second
  end

  test "form-action permits the oauth provider the handoff form redirects to" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    form_action = csp[/form-action ([^;]+)/, 1]

    # The handoff form posts to this app, but the response is a redirect to the provider and
    # form-action is enforced against the navigation's destination. Left at 'self' the browser
    # dropped that redirect and the user never left /login.
    assert_includes form_action, "'self'"
    assert_includes form_action, "https://auth.hackclub.com"
  end

  test "inline script nonces match the header" do
    sign_in_as users(:one)
    get design_url(designs(:one))

    csp = response.headers["Content-Security-Policy"]
    header_nonce = csp[NONCE_RE, 1]
    body_nonces = response.body.scan(/<script nonce="([^"]+)"/).flatten.uniq

    assert body_nonces.any?, "expected at least one nonced inline script on the design page"
    body_nonces.each { |n| assert_equal header_nonce, n, "body nonce does not match header" }
  end
end
