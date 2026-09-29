require Rails.root.join("lib/omniauth/rails_csrf_protection")
require Rails.root.join("lib/omniauth/strategies/hackclub")

Rails.application.config.middleware.use OmniAuth::Builder do
  # No callback_url override: the strategy derives the callback from APP_URL, which is the
  # origin registered on the Hack Club app. An override here was being applied verbatim and
  # a bare origin there sent the user back to the site root instead of the callback.
  provider :hackclub,
           ENV.fetch("HACKCLUB_CLIENT_ID", ""),
           ENV.fetch("HACKCLUB_CLIENT_SECRET", ""),
           scope: "profile email name slack_id verification_status"
end

# The request phase must be a POST carrying a CSRF token. Leaving it open to GET with
# request_validation_phase disabled lets another site start an OAuth flow in a victim's
# browser (login CSRF): if the IdP reuses an existing Hack Club session the victim is
# silently signed in as whoever the attacker chose, and everything they do from then on
# lands in that account. OmniAuth's default AuthenticityTokenProtection is what
# prevents it, so it is deliberately left enabled.
OmniAuth.config.allowed_request_methods = [ :post ]
# The default validation phase expects a Rack::Protection token, which nothing here issues,
# so every login failed with "Attack prevented by OmniAuth::AuthenticityTokenProtection".
# Keep the protection (and its failure routing) but let Rails' token satisfy it.
OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(
  allow_if: ->(env) { OmniAuth::RailsCsrfProtection.valid?(env) }
)
OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = proc { |env| SessionsController.action(:failure).call(env) }
