require "test_helper"

class DevlogControllerTest < ActionDispatch::IntegrationTest
  test "should get update" do
    devlog = devlogs(:one)
    patch devlog_path(devlog), params: { devlog: { title: "Updated" } }
    assert_response :redirect
  end
end
