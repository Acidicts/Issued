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
  class Notification < ApplicationRecord
    belongs_to :user

    attribute :read, :boolean, default: false
    attribute :priority, :integer
    enum :priority, {
      approved: 0,
      rejected: 1,
      pending:  2,
      urgent:   3,
      review:   4,
      shop:     5,
      order:    6,
      system:   7
    }, prefix: :priority

    def read
      update!(read: true)
    end

    # A plain notification asks nothing, so it is always markable read. Branches that
    # expect an answer override this and guard themselves with `check_read`.
    def answered?
      true
    end
  end
end
