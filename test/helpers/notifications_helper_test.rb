require "test_helper"

class NotificationsHelperTest < ActionView::TestCase
  include NotificationsHelper
  include IconsHelper

  test "renders a plain body unchanged" do
    assert_equal "Hello world", render_notification_body("Hello world")
  end

  test "replaces a user token with a name pill" do
    admin = users(:admin_user)
    result = render_notification_body("{{user:#{admin.id}}} added 5 threads")

    assert_includes result, admin.name
    assert_includes result, "user-pill"
  end

  test "includes the admin badge svg for admin users" do
    admin = users(:admin_user)
    result = render_notification_body("{{user:#{admin.id}}} did something")

    assert_includes result, "admin-badge"
  end

  test "does not include the admin badge for non-admin users" do
    non_admin = users(:one)
    result = render_notification_body("{{user:#{non_admin.id}}} did something")

    refute_includes result, "admin-badge"
  end

  test "shows unknown user for a token referencing a missing id" do
    result = render_notification_body("{{user:999999}} did something")

    assert_includes result, "unknown user"
  end

  test "escapes html in the surrounding body text" do
    result = render_notification_body("<script>alert(1)</script>")

    refute_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
  end
end
