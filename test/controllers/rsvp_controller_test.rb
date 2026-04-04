require "test_helper"

class RsvpControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rsvp_url
    assert_response :success
  end
end
