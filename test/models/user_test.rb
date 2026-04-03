require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "updates ysws eligibility from auth info" do
    user = User.new

    user.update_ysws_eligibility_from_auth_info(
      "yws_eligible" => "true"
    )
    assert_equal true, user.ysws_eligible

    user.update_ysws_eligibility_from_auth_info(
      "ysws_eligible" => nil,
      "yws_eligible" => nil
    )
    assert_equal false, user.ysws_eligible
  end
end
