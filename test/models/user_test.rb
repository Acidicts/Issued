require "test_helper"

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  credits                :integer
#  email                  :string
#  guide                  :boolean          default(FALSE), not null
#  hackclub_access_token  :text
#  hackclub_refresh_token :text
#  name                   :string
#  role                   :integer
#  threads                :integer
#  veri_level             :integer
#  ysws_eligible          :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  slack_id               :string
#
class UserTest < ActiveSupport::TestCase
  test "add_threads increases balance and creates a balance event" do
    user = users(:one)
    starting = user.threads.to_i

    user.add_threads(amount: 10, initiator: users(:admin_user))

    assert_equal starting + 10, user.reload.threads
    event = user.balance_events.order(:created_at).last
    assert_equal 10, event.amount
    assert_equal users(:admin_user), event.initiator
  end

  test "add_threads creates a notification referencing the initiator" do
    user = users(:one)

    assert_difference -> { user.notifications.count }, 1 do
      user.add_threads(amount: 5, initiator: users(:admin_user))
    end

    notification = user.notifications.order(:created_at).last
    assert_includes notification.body, "{{user:#{users(:admin_user).id}}}"
  end

  test "remove_threads decreases balance and creates a balance event" do
    user = users(:one)
    user.add_threads(amount: 20, initiator: users(:admin_user))
    starting = user.reload.threads

    user.remove_threads(amount: 7, initiator: users(:admin_user))

    assert_equal starting - 7, user.reload.threads
    event = user.balance_events.order(:created_at).last
    assert_equal(-7, event.amount)
  end

  test "remove_threads accepts name and comment as keyword args" do
    user = users(:one)

    assert_nothing_raised do
      user.remove_threads(name: "manual adjustment", comment: "test note", amount: 3, initiator: users(:admin_user))
    end

    event = user.balance_events.order(:created_at).last
    assert_equal "manual adjustment", event.name
    assert_equal "test note", event.comment
  end

  test "calculate_threads sums balance_events including unsaved built records" do
    user = users(:one)
    user.balance_events.build(initiator: users(:admin_user), amount: 15, name: "test", comment: "test")

    user.calculate_threads

    assert_equal 15, user.threads
  end

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

  test "fetch_live_hackclub_oauth_info falls back to in-memory user token" do
    user = User.new(name: "Token User", slack_id: "UTOKEN1", ysws_eligible: false, hackclub_access_token: "db-access-token")
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

  test "refresh_ysws_eligibility! updates veri_level and ysws_eligible from identity" do
    user = User.new(veri_level: :unknown, ysws_eligible: false)
    user.define_singleton_method(:fetch_live_hackclub_identity) do
      { "verification_status" => "verified", "ysws_eligible" => "true" }
    end

    user.refresh_ysws_eligibility!
    assert_equal "verified", user.veri_level
    assert_equal true, user.ysws_eligible
  end

  test "veri_level enum has a declared attribute type" do
    assert_kind_of ActiveRecord::Enum::EnumType, User.attribute_types["veri_level"]
  end

  test "has many designs" do
    user = users(:one)
    assert_respond_to user, :designs
  end

  test "has many orders" do
    user = users(:one)
    assert_respond_to user, :orders
  end

  test "has many rsvps" do
    user = users(:one)
    assert_respond_to user, :rsvps
  end

  test "has many notifications" do
    user = users(:one)
    assert_respond_to user, :notifications
  end

  test "verified_for_ysws? returns true when verified and eligible" do
    user = User.new(veri_level: :verified, ysws_eligible: true)
    assert user.verified_for_ysws?
  end

  test "verified_for_ysws? returns false when not verified" do
    user = User.new(veri_level: :pending, ysws_eligible: true)
    refute user.verified_for_ysws?
  end

  test "verified_for_ysws? returns false when not eligible" do
    user = User.new(veri_level: :verified, ysws_eligible: false)
    refute user.verified_for_ysws?
  end

  test "admin? returns true for admin role" do
    user = User.new(role: :admin)
    assert user.admin?
  end

  test "admin? returns true for superadmin role" do
    user = User.new(role: :superadmin)
    assert user.admin?
  end

  test "admin? returns true for reviewer role" do
    user = User.new(role: :reviewer)
    assert user.admin?
  end

  test "admin? returns false for user role" do
    user = User.new(role: :user)
    refute user.admin?
  end

  test "role enum values" do
    user = User.new
    assert_equal "user", user.role

    user.role = :admin
    assert_equal "admin", user.role

    user.role = :superadmin
    assert_equal "superadmin", user.role

    user.role = :reviewer
    assert_equal "reviewer", user.role
  end

  test "veri_level enum values" do
    user = User.new
    assert_equal "unknown", user.veri_level

    user.veri_level = :needs_submission
    assert_equal "needs_submission", user.veri_level

    user.veri_level = :pending
    assert_equal "pending", user.veri_level

    user.veri_level = :verified
    assert_equal "verified", user.veri_level

    user.veri_level = :ineligible
    assert_equal "ineligible", user.veri_level
  end

  test "ysws_eligible validates inclusion" do
    user = User.new(name: "Test", slack_id: "UTEST", veri_level: :verified)
    user.ysws_eligible = true
    assert user.valid?

    user.ysws_eligible = false
    assert user.valid?
  end

  test "refresh_ysws_eligibility! returns false when no identity" do
    user = User.new(veri_level: :unknown, ysws_eligible: false)
    user.define_singleton_method(:fetch_live_hackclub_identity) { nil }

    result = user.refresh_ysws_eligibility!
    assert_equal false, result
  end

  test "threads defaults to zero" do
    user = User.new
    assert_equal 0, user.threads
  end
end
