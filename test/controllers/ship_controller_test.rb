require "test_helper"

class ShipControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get ship_show_url
    assert_response :success
  end
end
