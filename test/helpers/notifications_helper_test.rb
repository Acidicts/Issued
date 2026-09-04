require "test_helper"

class NotificationsHelperTest < ActionView::TestCase
  include NotificationsHelper

  test "renders a plain body unchanged" do
    notification = Notification.new(body: "Hello world", user: users(:one))
    assert_equal "Hello world", render_notification_body(notification)
  end

  test "replaces a user token with a name pill" do
    admin = users(:admin_user)
    notification = Notification.new(body: "{{user:#{admin.id}}} added 5 threads", user: users(:one))

    result = render_notification_body(notification)

    assert_includes result, admin.name
    assert_includes result, "user-pill"
  end

  test "includes the admin badge svg for admin users" do
    admin = users(:admin_user)
    notification = Notification.new(body: "{{user:#{admin.id}}} did something", user: users(:one))

    result = render_notification_body(notification)

    assert_includes result, "admin-badge"
  end

  test "does not include the admin badge for non-admin users" do
    non_admin = users(:one)
    notification = Notification.new(body: "{{user:#{non_admin.id}}} did something", user: users(:two))

    result = render_notification_body(notification)

    refute_includes result, "admin-badge"
  end

  test "shows unknown user for a token referencing a missing id" do
    notification = Notification.new(body: "{{user:999999}} did something", user: users(:one))

    result = render_notification_body(notification)

    assert_includes result, "unknown user"
  end

  test "escapes html in the surrounding body text" do
    notification = Notification.new(body: "<script>alert(1)</script>", user: users(:one))

    result = render_notification_body(notification)

    refute_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
  end
end
