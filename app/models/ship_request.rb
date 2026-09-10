# == Schema Information
#
# Table name: ship_requests
#
#  id         :bigint           not null, primary key
#  body       :text
#  status     :integer
#  title      :string
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
  has_many :devlogs, dependent: :nullify

  has_one :image, as: :devlog

  def total_time_seconds
    Rails.cache.fetch("#{cache_key_with_version}/devlogs_sum", expires_in: 4.days) do
      devlogs.sum(:time)
    end
  end

  def refresh_total_time
    Rails.cache.fetch("#{cache_key_with_version}/devlogs_sum", expires_in: 4.days, force: true) do
      devlogs.sum(:time)
    end
  end
end
