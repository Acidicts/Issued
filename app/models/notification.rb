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
class Notification < ApplicationRecord
  belongs_to :user

  attribute :priority, :integer
  enum :priority, {
    urgent: 0,
    middling: 1,
    info: 2,
    review: 3,
    system: 4,
    standard: 5
  }

  def read
    update!(read: true)
  end
end
