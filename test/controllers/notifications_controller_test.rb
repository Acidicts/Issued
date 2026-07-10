require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get notifications_url
    assert_response :success
  end

  test "index requires login" do
    delete logout_url

    get notifications_url
    assert_redirected_to root_url
  end
end
