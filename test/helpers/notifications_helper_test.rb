require "test_helper"

class NotificationsHelperTest < ActionView::TestCase
  include ApplicationHelper
  include IconsHelper

  test "renders a plain body unchanged" do
    assert_equal "Hello world", render_encoded("Hello world")
  end

  test "replaces a user token with a name pill" do
    admin = users(:admin_user)
    result = render_encoded("{{user:#{admin.id}}} added 5 threads")

    assert_includes result, admin.name
    assert_includes result, "user-pill"
  end

  test "does not include the admin badge for non-admin users" do
    non_admin = users(:one)
    result = render_encoded("{{user:#{non_admin.id}}} did something")

    refute_includes result, "admin-badge"
  end

  test "shows unknown user for a token referencing a missing id" do
    result = render_encoded("{{user:999999}} did something")

    assert_includes result, "unknown user"
  end

  test "escapes html in the surrounding body text" do
    result = render_encoded("<script>alert(1)</script>")

    refute_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
  end
end
