require "action_controller"

module OmniAuth
  # OmniAuth 2 checks its request phase with Rack::Protection::AuthenticityToken, which mints
  # and validates its own token in `session[:csrf]`. Rails' `authenticity_token` is a
  # different value bound to `session[:_csrf_token]`, so a token Rails issued is always
  # rejected and the login handoff can never start. Reuse Rails' own verification instead, so
  # the request phase still requires a CSRF token but only one token scheme is in play.
  module RailsCsrfProtection
    module_function

    def valid?(env)
      controller = controller_for(ActionDispatch::Request.new(env))

      controller.send(:valid_request_origin?) && controller.send(:any_authenticity_token_valid?)
    rescue StandardError => e
      Rails.logger.warn("OmniAuth request phase CSRF check errored: #{e.class} #{e.message}")
      false
    end

    # Rails skips token verification entirely when forgery protection is off (the test
    # environment does that by default). The request phase is the one place where an
    # unprotected entry would let another site sign a victim into an attacker's account, so
    # it is verified no matter what that setting says.
    def controller_for(request)
      controller = ApplicationController.new
      controller.set_request!(request)
      controller.set_response!(ActionDispatch::Response.new)
      controller
    end
  end
end
