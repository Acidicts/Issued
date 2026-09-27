require "test_helper"

class BooleanNotificationTest < ActiveSupport::TestCase
  test "branches from Notification" do
    assert_operator Notifications::BooleanNotification, :<, Notifications::Notification
  end

  test "stores a yes input" do
    notification = Notifications::BooleanNotification.new(user: users(:one), body: "Ship shipped", yes_no: "yes")

    assert_predicate notification, :valid?
    assert_equal true, notification.value
    assert_equal "yes", notification.yes_no
  end

  test "stores a no input" do
    notification = Notifications::BooleanNotification.new(user: users(:one), body: "Ship shipped", yes_no: "no")

    assert_predicate notification, :valid?
    assert_equal false, notification.value
    assert_equal "no", notification.yes_no
  end

  test "casts common yes inputs" do
    [ true, 1, "1", "true", "t", "yes", "y", "on", :true, :yes ].each do |input|
      notification = Notifications::BooleanNotification.new(user: users(:one), value: nil)
      notification.yes_no = input

      assert_equal true, notification.value, "expected #{input.inspect} to store a yes input"
    end
  end

  test "casts common no inputs" do
    [ false, 0, "0", "false", "f", "no", "n", "off", :false, :no ].each do |input|
      notification = Notifications::BooleanNotification.new(user: users(:one), value: nil)
      notification.yes_no = input

      assert_equal false, notification.value, "expected #{input.inspect} to store a no input"
    end
  end

  test "requires a yes or no input" do
    notification = Notifications::BooleanNotification.new(user: users(:one), body: "Ship shipped")

    assert_not notification.valid?
    assert_includes notification.errors[:value], "must be a yes or no input"
  end

  test "rejects an unrecognised input" do
    notification = Notifications::BooleanNotification.new(user: users(:one), body: "Ship shipped", yes_no: "maybe")

    assert_not notification.valid?
    assert_nil notification.value
    assert_includes notification.errors[:value], "must be a yes or no input"
  end

  test "yes_no is nil until an input is given" do
    assert_nil Notifications::BooleanNotification.new(user: users(:one)).yes_no
  end

  test "persists the yes or no input and reloads as a BooleanNotification" do
    notification = Notifications::BooleanNotification.create!(user: users(:one), body: "Ship shipped", yes_no: "yes")

    reloaded = Notifications::Notification.find(notification.id)
    assert_instance_of Notifications::BooleanNotification, reloaded
    assert_equal true, reloaded.value
    assert_equal "yes", reloaded.yes_no
  end

  test "yes or no input can be changed and saved" do
    notification = notifications(:boolean_one)
    notification.update!(yes_no: "no")

    assert_equal false, notification.reload.value
    assert_equal "no", notification.yes_no
  end
end
