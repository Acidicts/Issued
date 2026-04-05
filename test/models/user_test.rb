require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "fetch_live_hackclub_oauth_info returns parsed me payload" do
    user = User.new
    parsed_payload = { "identity" => { "name" => "Alex" }, "scopes" => [ "profile" ] }
    fake_response = Struct.new(:parsed).new(parsed_payload)
    fake_token = Struct.new(:response) do
      def get(_path)
        response
      end
    end.new(fake_response)

    Current.hackclub_access_token = "access-token"
    user.define_singleton_method(:hackclub_oauth_access_token) do |token:, refresh_token:|
      raise "unexpected token" unless token == "access-token"
      fake_token
    end

    assert_equal parsed_payload, user.fetch_live_hackclub_oauth_info
  ensure
    Current.hackclub_access_token = nil
    Current.hackclub_refresh_token = nil
  end

  test "fetch_live_hackclub_oauth_info returns nil without access token" do
    user = User.new

    Current.hackclub_access_token = nil
    assert_nil user.fetch_live_hackclub_oauth_info
  ensure
    Current.hackclub_access_token = nil
    Current.hackclub_refresh_token = nil
  end

  test "fetch_live_hackclub_oauth_info falls back to ENV access token" do
    user = User.new
    parsed_payload = { "identity" => { "name" => "Alex" } }
    fake_response = Struct.new(:parsed).new(parsed_payload)
    fake_token = Struct.new(:response) do
      def get(_path)
        response
      end
    end.new(fake_response)

    Current.hackclub_access_token = nil
    previous_env_access = ENV["HACKCLUB_ACCESS_TOKEN"]
    ENV["HACKCLUB_ACCESS_TOKEN"] = "env-access-token"

    user.define_singleton_method(:hackclub_oauth_access_token) do |token:, refresh_token:|
      raise "unexpected token" unless token == "env-access-token"
      fake_token
    end

    assert_equal parsed_payload, user.fetch_live_hackclub_oauth_info
  ensure
    ENV["HACKCLUB_ACCESS_TOKEN"] = previous_env_access
    Current.hackclub_access_token = nil
    Current.hackclub_refresh_token = nil
  end

  test "fetch_live_hackclub_oauth_info falls back to persisted user token" do
    user = User.create!(name: "Token User", slack_id: "UTOKEN1", verified: true, ysws_eligible: false)
    user.update!(hackclub_access_token: "db-access-token")
    parsed_payload = { "identity" => { "name" => "Token User" } }
    fake_response = Struct.new(:parsed).new(parsed_payload)
    fake_token = Struct.new(:response) do
      def get(_path)
        response
      end
    end.new(fake_response)

    Current.hackclub_access_token = nil
    Current.hackclub_refresh_token = nil

    user.define_singleton_method(:hackclub_oauth_access_token) do |token:, refresh_token:|
      raise "unexpected token" unless token == "db-access-token"
      fake_token
    end

    assert_equal parsed_payload, user.fetch_live_hackclub_oauth_info
  ensure
    Current.hackclub_access_token = nil
    Current.hackclub_refresh_token = nil
  end

  test "updates ysws eligibility from auth info" do
    user = User.new

    user.update_ysws_eligibility_from_auth_info(
      "yws_eligible" => "true"
    )
    assert_equal true, user.ysws_eligible

    user.update_ysws_eligibility_from_auth_info(
      "ysws_eligible" => nil,
      "yws_eligible" => nil
    )
    assert_equal false, user.ysws_eligible
  end

  test "update_veri_level maps verification status to enum" do
    user = User.new(veri_level: :unknown)
    user.define_singleton_method(:fetch_live_hackclub_identity) do
      { "verification_status" => "verified" }
    end

    user.update_veri_level
    assert_equal "verified", user.veri_level
  end
end
