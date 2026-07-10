require "test_helper"
require "securerandom"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      slack_id: "UADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :admin
    )
    sign_in_as(@admin)
  end

  test "admin can list orders" do
    get admin_orders_url
    assert_response :success
  end

  test "admin can cancel order" do
    order = orders(:one)
    order.update!(status: :pending)

    delete cancel_admin_order_url(order)
    assert_redirected_to admin_orders_url
    assert_equal "cancelled", order.reload.status
  end

  test "non-admin cannot access orders" do
    non_admin = User.create!(
      name: "Regular User",
      slack_id: "UNONADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :user
    )
    sign_in_as(non_admin)

    get admin_orders_url
    assert_redirected_to root_url
  end
end
