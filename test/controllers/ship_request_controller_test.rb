require "test_helper"

class ShipRequestControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    design = designs(:one)
    get ship_request_new_url(design_id: design.id)
    assert_response :success
  end
end
