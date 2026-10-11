require "test_helper"

class Fufillment::BatchesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in_as(users(:admin_user))
    get fufillment_batches_url
    assert_response :success
  end

  test "should get show" do
    sign_in_as(users(:admin_user))
    get fufillment_batch_url(batches(:one))
    assert_response :success
  end

  test "should get edit" do
    sign_in_as(users(:admin_user))
    get edit_fufillment_batch_url(batches(:one))
    assert_response :success
  end

  test "should update existing batch instead of creating a new one" do
    sign_in_as(users(:admin_user))
    assert_no_difference("Batch.count") do
      patch fufillment_batch_url(batches(:one)), params: { batch: { status: :completed } }
    end
    assert_redirected_to fufillment_batch_url(batches(:one))
    assert_equal "completed", batches(:one).reload.status
  end

  test "a user without the fufillment role is sent home" do
    sign_in_as(users(:one))
    get fufillment_batches_url
    assert_redirected_to root_url
  end
end
