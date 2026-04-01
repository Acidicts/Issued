require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Hackclub < OmniAuth::Strategies::OAuth2
      option :name, "hackclub"

      option :client_options, {
        site: "https://auth.hackclub.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token"
      }

      uid { raw_info.dig("identity", "id") }

      info do
        identity = raw_info["identity"] || {}
        {
          name: [ identity["first_name"], identity["last_name"] ].compact.join(" ").strip.presence,
          email: identity["primary_email"],
          slack_id: identity["slack_id"],
          verification_status: identity["verification_status"],
          ysws_eligible: identity["ysws_eligible"] || identity["yws_eligible"]
        }
      end

      extra do
        { "raw_info" => raw_info }
      end

      # Keep authorize and token-exchange redirect_uri identical for the active host.
      # This avoids invalid_grant errors caused by host/port drift in development.
      def callback_url
        options[:callback_url].presence || "#{request.base_url}#{script_name}#{callback_path}"
      end

      def raw_info
        @raw_info ||= access_token.get("/api/v1/me").parsed
      end
    end
  end
end
