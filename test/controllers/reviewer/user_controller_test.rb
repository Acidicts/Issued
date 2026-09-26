require "test_helper"

class Reviewer::UserControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    sign_in_as(users(:admin_user))
    get reviewer_user_url(users(:one))
    assert_response :success
  end
end
