require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get orders_path
    assert_response :success
  end

  test "index requires login" do
    delete logout_url

    get orders_url
    assert_redirected_to root_url
  end

  test "new shows order form" do
    product = products(:one)
    get new_order_path(product_id: product.id)
    assert_response :success
  end

  test "create places order and redirects" do
    design = designs(:one)
    product = products(:one)

    assert_difference("Order.count", 1) do
      post orders_path, params: { order: { design_id: design.id, product_id: product.id } }
    end
    assert_redirected_to orders_path
  end

  test "create with invalid params does not place order" do
    assert_no_difference("Order.count") do
      post orders_path, params: { order: { design_id: 99999, product_id: 99999 } }
    end
  end
end
