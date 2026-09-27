require "test_helper"

# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  body       :text
#  kind       :string
#  priority   :integer
#  read       :boolean
#  time       :string
#  type       :string
#  value      :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_notifications_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class NotificationTest < ActiveSupport::TestCase
  test "valid notification" do
    notification = Notifications::Notification.new(user: users(:one), body: "Test notification", priority: :system)
    assert notification.valid?
  end

  test "belongs to user" do
    notification = notifications(:one)
    assert_equal users(:one), notification.user
  end

  test "priority enum values" do
    notification = Notifications::Notification.new

    %w[approved rejected pending urgent review shop order system].each do |value|
      notification.priority = value
      assert_equal value, notification.priority
    end
  end

  test "priority enum predicates are prefixed" do
    notification = Notifications::Notification.new(priority: :order)

    assert notification.priority_order?
    assert_not notification.priority_approved?
  end

  test "read updates read attribute" do
    notification = notifications(:one)
    notification.update!(read: false)

    notification.read
    assert_equal true, notification.reload.read
  end

  test "type branches into a BooleanNotification" do
    notification = Notifications::BooleanNotification.create!(user: users(:one), body: "Ship shipped", yes_no: "yes")

    assert_equal "Notifications::BooleanNotification", notification.type
    assert_instance_of Notifications::BooleanNotification, Notifications::Notification.find(notification.id)
  end

  test "type branches into a TextNotification" do
    notification = Notifications::TextNotification.create!(user: users(:one), body: "Ship shipped", text: "Your ship was approved")

    assert_equal "Notifications::TextNotification", notification.type
    assert_instance_of Notifications::TextNotification, Notifications::Notification.find(notification.id)
  end

  test "untyped notifications stay a Notification" do
    notification = Notifications::Notification.create!(user: users(:one), body: "Threads added", priority: :system)

    assert_nil notification.type
    assert_instance_of Notifications::Notification, Notifications::Notification.find(notification.id)
  end

  test "subclass scopes only return their own branch" do
    text = Notifications::TextNotification.create!(user: users(:one), body: "Ship shipped", text: "Your ship was approved")

    assert Notifications::TextNotification.all.all?(Notifications::TextNotification)
    assert_not Notifications::TextNotification.exists?(notifications(:one).id)

    notification = Notifications::Notification.find(text.id)
    assert notification.is_a?(Notifications::TextNotification)
  end

  test "branches inherit the shared notification behaviour" do
    notification = Notifications::TextNotification.create!(user: users(:one), body: "Ship shipped", text: "Your ship was approved", priority: :order)

    assert_equal users(:one), notification.user
    assert notification.priority_order?

    notification.read
    assert_equal true, notification.reload[:read]
  end

  # `type` has to stay in any `select` over notifications: without it Rails cannot
  # tell which branch a row belongs to and silently instantiates a plain Notification.
  test "a select without type silently loses the branch" do
    text = Notifications::TextNotification.create!(user: users(:one), body: "Ship shipped", text: "Your ship was approved")
    notifications = users(:one).notifications

    assert_instance_of Notifications::Notification, notifications.select(:id, :body).find(text.id)
    assert_instance_of Notifications::TextNotification, notifications.select(:id, :body, :type).find(text.id)
  end
end
