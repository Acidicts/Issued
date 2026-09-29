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

      # Keep authorize and token-exchange redirect_uri identical, and pin the origin to
      # APP_URL rather than the current request. On a preview deploy, a tunnel or localhost
      # the request host is not the origin registered on the Hack Club app, and the provider
      # compares redirect_uri byte-for-byte and then sends the browser to whatever it is
      # given: an origin-only value (or localhost) came back as a bare site root instead of
      # the callback, so login silently never completed. APP_URL is the registered origin;
      # the callback path is ours to append.
      def callback_url
        base = ENV["APP_URL"].to_s.strip.presence || request.base_url
        "#{base.chomp("/")}#{script_name}#{callback_path}"
      end

      def raw_info
        @raw_info ||= access_token.get("/api/v1/me").parsed
      end
    end
  end
end
