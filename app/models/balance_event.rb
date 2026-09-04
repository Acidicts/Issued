# == Schema Information
#
# Table name: balance_events
#
#  id           :bigint           not null, primary key
#  amount       :integer
#  comment      :text
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  initiator_id :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_balance_events_on_initiator_id  (initiator_id)
#  index_balance_events_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (initiator_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class BalanceEvent < ApplicationRecord
  belongs_to :user
  belongs_to :initiator, class_name: "User"
end
