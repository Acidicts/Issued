require "test_helper"

class DevlogControllerTest < ActionDispatch::IntegrationTest
  test "should get update" do
    get devlog_update_url
    assert_response :success
  end
end
