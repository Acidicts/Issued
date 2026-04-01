require Rails.root.join("lib/omniauth/strategies/hackclub")

Rails.application.config.middleware.use OmniAuth::Builder do
  provider_options = {
    scope: "profile email name slack_id verification_status"
  }
  provider_options[:callback_url] = ENV["HACKCLUB_REDIRECT_URI"] if ENV["HACKCLUB_REDIRECT_URI"].present?

  provider :hackclub,
           ENV.fetch("HACKCLUB_CLIENT_ID", ""),
           ENV.fetch("HACKCLUB_CLIENT_SECRET", ""),
           **provider_options
end

OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.logger = Rails.logger
OmniAuth.config.request_validation_phase = nil
OmniAuth.config.on_failure = proc { |env| SessionsController.action(:failure).call(env) }
