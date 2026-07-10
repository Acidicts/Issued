require "test_helper"

class ShopControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shop_url
    assert_response :success
  end
end
