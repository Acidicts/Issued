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
  class BooleanNotification < Notification
    YES_INPUTS = [ true, 1, "1", "true", "t", "yes", "y", "on", :true, :t, :yes, :y, :on ].freeze
    NO_INPUTS = [ false, 0, "0", "false", "f", "no", "n", "off", :false, :f, :no, :n, :off ].freeze
    YES_NO_LABELS = { true => "Yes", false => "No" }.freeze

    # `value` stays nil until the notification is answered, so it is only required once read.
    # `read?` cannot be used as the condition: `read` is overridden as a writer, so the
    # generated query method calls the writer and recurses.
    validates :value, inclusion: { in: [ true, false ], message: "must be a yes or no input" }, if: -> { self[:read] }
    validate  :check_read

    def answered?
      !value.nil?
    end

    # Keeps an unanswered notification unread: `update!(read: true)` raises instead of
    # silently marking it read. The attribute is read through the hash because `read` is
    # overridden as a writer, and calling it here would recurse through the validation.
    def check_read
      if self[:read] && !answered?
        errors.add(:value, "must be a yes or no input before the notification can be marked read")
      end
    end

    def yes_no
      return if value.nil?

      value ? "yes" : "no"
    end

    def yes_no_label
      YES_NO_LABELS[value]
    end

    def yes_no=(input)
      self.value = if YES_INPUTS.include?(input) then true
      elsif NO_INPUTS.include?(input) then false
      end
    end
  end
end
