require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get notifications_url
    assert_response :success
  end

  test "index requires login" do
    delete logout_url

    get notifications_url
    assert_redirected_to root_url
  end

  test "read marks the notification read and redirects back" do
    notification = notifications(:one)
    notification.update!(read: false)

    get read_notification_url(notification), headers: { "Referer" => notifications_url }

    assert_redirected_to notifications_url
    # `Notifications::Notification#read` is a writer, so read the attribute through the hash.
    assert_equal true, notification.reload[:read]
  end

  test "read cannot touch another user's notification" do
    notification = notifications(:two)

    get read_notification_url(notification)

    assert_response :not_found
    assert_equal false, notification.reload[:read]
  end

  test "index renders a reply form for an unread text notification" do
    notifications(:text_one).update!(read: false, text: nil)

    get notifications_url

    assert_select "form.notif-reply[action=?][method=?]", read_notification_path(notifications(:text_one)), "get"
    assert_select "form.notif-reply textarea[name=?]", "text"
  end

  test "read stores the reply text" do
    notification = notifications(:text_one)
    notification.update!(read: false, text: nil)

    get read_notification_url(notification, text: "looks good, shipping it"),
      headers: { "Referer" => notifications_url }

    assert_redirected_to notifications_url
    assert_equal "looks good, shipping it", notification.reload.text
    assert_equal true, notification[:read]
  end

  test "read without a reply still marks the notification read" do
    notification = notifications(:text_one)
    notification.update!(read: false, text: nil)

    get read_notification_url(notification, text: ""),
      headers: { "Referer" => notifications_url }

    assert_redirected_to notifications_url
    assert_nil notification.reload.text
    assert_equal true, notification[:read]
  end

  test "index renders yes and no choices for an unread boolean notification" do
    notifications(:boolean_one).update!(read: false, value: nil)

    get notifications_url

    assert_select "form.notif-boolean-reply[action=?]", read_notification_path(notifications(:boolean_one)) do
      assert_select "button[name=?][value=?]", "boolean", "true", text: "Yes"
      assert_select "button[name=?][value=?]", "boolean", "false", text: "No"
    end
  end

  test "answering yes stores true and displays Yes" do
    notification = notifications(:boolean_one)
    notification.update!(read: false, value: nil)

    get read_notification_url(notification, boolean: "true"),
      headers: { "Referer" => notifications_url }

    assert_equal true, notification.reload.value
    assert_equal "Yes", notification.yes_no_label
    assert_equal true, notification[:read]
  end

  test "answering no stores false and displays No" do
    notification = notifications(:boolean_one)
    notification.update!(read: false, value: nil)

    get read_notification_url(notification, boolean: "false"),
      headers: { "Referer" => notifications_url }

    assert_equal false, notification.reload.value
    assert_equal "No", notification.yes_no_label
    assert_equal true, notification[:read]
  end

  test "an unanswered boolean notification displays no answer" do
    assert_nil notifications(:boolean_one).tap { |n| n.update_columns(value: nil) }.yes_no_label
  end

  test "read without an answer leaves a boolean notification unread" do
    notification = notifications(:boolean_one)
    notification.update!(read: false, value: nil)

    get read_notification_url(notification), headers: { "Referer" => notifications_url }

    assert_redirected_to notifications_url
    assert_nil notification.reload.value
    assert_equal false, notification[:read]
  end
end
