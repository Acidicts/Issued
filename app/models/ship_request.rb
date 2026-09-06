# == Schema Information
#
# Table name: ship_requests
#
#  id         :bigint           not null, primary key
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  design_id  :bigint           not null
#
# Indexes
#
#  index_ship_requests_on_design_id  (design_id)
#
# Foreign Keys
#
#  fk_rails_...  (design_id => designs.id)
#
class ShipRequest < ApplicationRecord
  belongs_to :design
  has_many :ships, dependent: :destroy
  has_many :devlogs, dependent: :destroy
end
