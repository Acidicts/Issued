require "test_helper"

class RsvpControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rsvp_url
    assert_response :success
  end

  test "submit requires login" do
    post rsvp_submit_url
    assert_redirected_to root_url
  end

  test "submit creates rsvp when logged in" do
    user = User.create!(
      name: "New RSVP User",
      slack_id: "URSVP#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false
    )
    sign_in_as(user)

    old_running = ENV["RUNNING"]
    old_ended = ENV["ENDED"]
    ENV["RUNNING"] = "false"
    ENV["ENDED"] = "false"

    assert_difference("Rsvp.count", 1) do
      post rsvp_submit_url
    end
    assert_redirected_to rsvp_thanks_url
  ensure
    ENV["RUNNING"] = old_running
    ENV["ENDED"] = old_ended
  end

  test "submit rejects when running" do
    sign_in_as(users(:one))
    old_running = ENV["RUNNING"]
    ENV["RUNNING"] = "true"

    post rsvp_submit_url
    assert_redirected_to rsvp_url
    assert_equal "RSVPs are closed right now.", flash[:alert]
  ensure
    ENV["RUNNING"] = old_running
  end
end
