require "test_helper"
require "securerandom"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @target_user = create_user(name: "Target User", role: :user)
  end

  test "superadmin can update another user's role" do
    superadmin = create_user(name: "Super Admin", role: :superadmin)
    sign_in_as(superadmin)

    patch admin_user_url(@target_user), params: {
      user: {
        name: @target_user.name,
        slack_id: @target_user.slack_id,
        ysws_eligible: "1",
        role: "admin"
      }
    }

    assert_redirected_to admin_users_url
    assert_equal "admin", @target_user.reload.role
  end

  test "admin cannot escalate another user's role" do
    admin = create_user(name: "Admin User", role: :admin)
    sign_in_as(admin)

    patch admin_user_url(@target_user), params: {
      user: {
        name: "Updated Name",
        slack_id: @target_user.slack_id,
        ysws_eligible: "0",
        role: "superadmin"
      }
    }

    assert_redirected_to admin_users_url
    @target_user.reload
    assert_equal "user", @target_user.role
    assert_equal "Updated Name", @target_user.name
  end

  private

  def create_user(name:, role:)
      User.create!(
        name: name,
        slack_id: "U#{SecureRandom.hex(4)}",
        veri_level: :verified,
        ysws_eligible: false,
        role: role
      )
  end
end
