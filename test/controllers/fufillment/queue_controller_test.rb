require "test_helper"

class Fufillment::QueueControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in_as(users(:admin_user))
    get fufillment_queue_index_url
    assert_response :success
  end

  test "should get show" do
    sign_in_as(users(:admin_user))
    get fufillment_queue_url(orders(:one))
    assert_response :success
  end

  test "should get edit" do
    sign_in_as(users(:admin_user))
    get edit_fufillment_queue_url(orders(:one))
    assert_response :success
  end

  test "should update order status" do
    sign_in_as(users(:admin_user))
    patch fufillment_queue_url(orders(:one)), params: { order: { status: :processing } }
    assert_redirected_to fufillment_queue_index_path
    assert_equal "processing", orders(:one).reload.status
  end

  # The queue is fufillment-only, so a plain user must never see it.
  test "a user without the fufillment role is sent home" do
    sign_in_as(users(:one))
    get fufillment_queue_index_url
    assert_redirected_to root_url
  end
end
