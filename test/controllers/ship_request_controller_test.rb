require "test_helper"

class ShipRequestControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get ship_request_new_url
    assert_response :success
  end
end
