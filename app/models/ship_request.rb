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
  has_one :ship, dependent: :destroy
  has_many :devlogs, dependent: :nullify

  has_one :review, as: :reviewed
  has_one :image, as: :devlog
  has_many :comments, as: :commentable

  enum :status, { pending: 0, approved: 1, rejected: 2, elevated: 3 }
  attribute :status, default: :pending

  # A ship request only becomes public once it has been reviewed, either by
  # being shipped, rejected, or by having a review attached to it. Anything
  # still awaiting review stays visible to its owner, admins and reviewers.
  def publicly_visible?
    review.present? || ship.present?
  end

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
