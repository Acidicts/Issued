require "test_helper"
require "securerandom"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      slack_id: "UADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :admin
    )
  end

  test "admin can access dashboard" do
    sign_in_as(@admin)
    get admin_overview_url
    assert_response :success
  end

  test "non-admin is redirected from dashboard" do
    non_admin = User.create!(
      name: "Regular User",
      slack_id: "UNONADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :user
    )
    sign_in_as(non_admin)

    get admin_overview_url
    assert_redirected_to root_url
  end
end
