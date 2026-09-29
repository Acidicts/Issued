# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  body       :text
#  kind       :string
#  priority   :integer
#  read       :boolean
#  text       :text
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
module Notifications
  class TextNotification < Notification
    validates :body, presence: true
    validate  :check_read

    def answered?
      text.present?
    end

    # Keeps an unanswered notification unread: `update!(read: true)` raises instead of
    # silently marking it read. The attribute is read through the hash because `read` is
    # overridden as a writer, and calling it here would recurse through the validation.
    def check_read
      if self[:read] && !answered?
        errors.add(:text, "must be replied to before the notification can be marked read")
      end
    end
  end
end
