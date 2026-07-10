require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in_as(users(:one))
    get settings_path
    assert_response :success
  end

  test "requires login" do
    get settings_path
    assert_redirected_to root_url
  end
end
