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
      request = ActionDispatch::Request.new(env)
      controller = controller_for(request)

      # The request phase must be verified even when global forgery protection is disabled
      # (e.g. test environment), so check origin and token explicitly rather than relying on
      # helpers that short-circuit when protection is off.
      origin_valid?(request) && token_valid?(controller, request)
    rescue StandardError => e
      Rails.logger.warn("OmniAuth request phase CSRF check errored: #{e.class} #{e.message}")
      false
    end

    def origin_valid?(request)
      # Match ActionController::RequestForgeryProtection's origin check: a missing Origin
      # header is accepted (some non-browser clients), otherwise it must match base_url.
      # Fall back to the standard helper when protection state allows it to be meaningful.
      return true if request.origin.blank?

      if request.respond_to?(:origin_verified?) && ActionController::Base.allow_forgery_protection
        request.origin_verified?
      else
        request.origin == request.base_url
      end
    end

    def token_valid?(controller, request)
      # Prefer Rails' own comparison (handles masked tokens, per-form tokens, header, etc.)
      # but force the check even if protect_against_forgery? would be false.
      if ActionController::Base.allow_forgery_protection
        controller.send(:any_authenticity_token_valid?)
      else
        forced_token_valid?(controller, request)
      end
    end

    def forced_token_valid?(controller, request)
      tokens = []
      param = request.params[request_forgery_protection_token]
      tokens << param if param.present?
      header = request.headers["X-CSRF-Token"]
      tokens << header if header.present?
      return false if tokens.empty?

      session = request.session
      tokens.any? { |token| controller.send(:valid_authenticity_token?, session, token) }
    end

    def request_forgery_protection_token
      ActionController::Base.request_forgery_protection_token || :authenticity_token
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
