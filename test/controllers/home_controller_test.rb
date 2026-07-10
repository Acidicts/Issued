require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get about" do
    get about_url
    assert_response :success
  end

  test "should get faq" do
    get faq_url
    assert_response :success
  end

  test "should get rsvps" do
    get rsvps_url
    assert_response :success
  end

  test "rsvps_og_image returns svg" do
    get rsvps_og_image_url
    assert_response :success
    assert_match "image/svg+xml", response.content_type
  end
end
