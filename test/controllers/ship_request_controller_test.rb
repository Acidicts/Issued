require "test_helper"

class ShipRequestControllerTest < ActionDispatch::IntegrationTest
  test "should get next_step checks" do
    get next_step_ship_requests_path(design_id: designs(:one).id, step: "start")
    assert_response :success
  end

  test "should get next_step form" do
    get next_step_ship_requests_path(design_id: designs(:one).id, step: "checks")
    assert_response :success
  end

  test "should get next_step overview" do
    get next_step_ship_requests_path(design_id: designs(:one).id)
    assert_response :success
  end
end
