require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get orders_index_url
    assert_response :success
  end

  test "show without id route is not found" do
    get orders_show_url
    assert_response :not_found
  end

  test "new without required params is not found" do
    get orders_new_url
    assert_response :not_found
  end

  test "delete route responds" do
    get orders_delete_url
    assert_response :success
  end

  test "edit without id route is not found" do
    get orders_edit_url
    assert_response :not_found
  end
end
