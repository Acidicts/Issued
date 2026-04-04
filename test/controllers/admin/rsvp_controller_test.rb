require "test_helper"

class Admin::RsvpControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_rsvp_index_url
    assert_response :success
  end
end
