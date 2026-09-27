require "test_helper"

class TextNotificationTest < ActiveSupport::TestCase
  test "branches from Notification" do
    assert_operator Notifications::TextNotification, :<, Notifications::Notification
  end

  test "stores the text input separately from the body" do
    notification = Notifications::TextNotification.new(user: users(:one), body: "Ship shipped", text: "Your ship was approved")

    assert_predicate notification, :valid?
    assert_equal "Your ship was approved", notification.text
    assert_equal "Ship shipped", notification.body
  end

  test "requires a body to display" do
    notification = Notifications::TextNotification.new(user: users(:one), text: "Your ship was approved")

    assert_not notification.valid?
    assert_includes notification.errors[:body], "can't be blank"
  end

  test "allows an unanswered notification" do
    notification = Notifications::TextNotification.new(user: users(:one), body: "Ship shipped")

    assert_predicate notification, :valid?
    assert_nil notification.text
  end

  test "stores a blank reply without complaint" do
    notification = Notifications::TextNotification.new(user: users(:one), body: "Ship shipped", text: "   ")

    assert_predicate notification, :valid?
  end

  test "persists the text input and reloads as a TextNotification" do
    notification = Notifications::TextNotification.create!(user: users(:one), body: "Ship shipped", text: "Your ship was approved")

    reloaded = Notifications::Notification.find(notification.id)
    assert_instance_of Notifications::TextNotification, reloaded
    assert_equal "Your ship was approved", reloaded.text
    assert_equal "Ship shipped", reloaded.body
  end

  test "text can be changed and saved" do
    notification = notifications(:text_one)
    notification.update!(text: "Your ship was rejected")

    assert_equal "Your ship was rejected", notification.reload.text
  end
end
