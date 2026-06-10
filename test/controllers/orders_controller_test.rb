require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get orders_path
    assert_response :success
  end

  test "show without id route is not found" do
    get orders_show_path
    assert_response :not_found
  end

  test "new without required params is not found" do
    get orders_new_path
    assert_response :not_found
  end

  test "delete route responds" do
    get orders_delete_path
    assert_response :success
  end

  test "edit without id route is not found" do
    get orders_edit_path
    assert_response :not_found
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:hackclub)
  end
end
