require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get dashboard_path
    assert_response :success
  end

  test "index does not mark notifications as read" do
    notification = notifications(:one)
    notification.update!(read: false)

    get dashboard_path

    assert_response :success
    assert_equal false, notification.reload[:read]
  end
end
