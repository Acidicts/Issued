require "test_helper"

class UserControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    stub_slack_service do
      get user_url(users(:one))
    end
    assert_response :success
  end

  test "should get admin" do
    stub_slack_service do
      get admin_user_url(users(:one))
    end
    assert_response :success
  end

  private

  def stub_slack_service(&block)
    original = SlackService.instance_method(:profile_image)
    SlackService.define_method(:profile_image) { |_id| "https://example.com/avatar.png" }
    SlackService.define_method(:display_name) { |_id| "Test User" }
    block.call
  ensure
    SlackService.define_method(:profile_image, original)
    SlackService.define_method(:display_name, SlackService.instance_method(:display_name))
  end
end
