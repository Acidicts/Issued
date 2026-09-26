require "test_helper"

class Reviewer::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in_as(users(:admin_user))
    get reviewer_dashboard_url
    assert_response :success
  end
end
