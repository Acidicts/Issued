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
    notification = Notification.new(user: users(:one), body: "Test notification", priority: :standard)
    assert notification.valid?
  end

  test "belongs to user" do
    notification = notifications(:one)
    assert_equal users(:one), notification.user
  end

  test "priority enum values" do
    notification = Notification.new

    notification.priority = :urgent
    assert_equal "urgent", notification.priority

    notification.priority = :middling
    assert_equal "middling", notification.priority

    notification.priority = :info
    assert_equal "info", notification.priority

    notification.priority = :review
    assert_equal "review", notification.priority

    notification.priority = :system
    assert_equal "system", notification.priority

    notification.priority = :standard
    assert_equal "standard", notification.priority
  end

  test "read updates read attribute" do
    notification = notifications(:one)
    notification.update!(read: false)

    notification.read
    assert_equal true, notification.reload.read
  end
end
