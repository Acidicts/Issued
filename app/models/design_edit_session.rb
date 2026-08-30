# == Schema Information
#
# Table name: design_edit_sessions
#
#  id               :bigint           not null, primary key
#  activity_type    :string           default("edit")
#  duration_seconds :integer          default(0), not null
#  ended_at         :datetime
#  started_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  design_id        :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_design_edit_sessions_on_design_id                 (design_id)
#  index_design_edit_sessions_on_design_id_and_created_at  (design_id,created_at)
#  index_design_edit_sessions_on_user_id                   (user_id)
#  index_design_edit_sessions_on_user_id_and_created_at    (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#  fk_rails_...  (user_id => users.id)
#
class DesignEditSession < ApplicationRecord
  belongs_to :design
  belongs_to :user

  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }
end
