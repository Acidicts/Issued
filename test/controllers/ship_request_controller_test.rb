require "test_helper"

class ShipRequestControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_ship_request_url(design_id: designs(:one).id)
    assert_response :success
  end

  test "should get create" do
    assert_difference("ShipRequest.count", 1) do
      post ship_requests_url, params: { ship_request: { design_id: designs(:one).id, title: "Test", body: "Body" } }
    end
    assert_redirected_to design_path(designs(:one))
  end
end
