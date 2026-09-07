require "test_helper"

class ShopControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should get index" do
    get shop_url
    assert_response :success
  end
end
