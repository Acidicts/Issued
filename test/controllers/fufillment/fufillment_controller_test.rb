require "test_helper"

class Fufillment::FufillmentControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in_as(users(:admin_user))
    get fufillment_fufillment_url
    assert_response :success
  end

  test "signed out visitors are sent home" do
    get fufillment_fufillment_url
    assert_redirected_to root_url
  end

  test "a user without the fufillment role is sent home" do
    sign_in_as(users(:one))
    get fufillment_fufillment_url
    assert_redirected_to root_url
  end
end
