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
