require "test_helper"

class UserControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get user_show_url
    assert_response :success
  end

  test "should get admin" do
    get user_admin_url
    assert_response :success
  end
end
