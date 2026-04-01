class DesignEditSession < ApplicationRecord
  belongs_to :design
  belongs_to :user

  validates :started_at, presence: true
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(started_at: :desc) }

  def ended?
    ended_at.present?
  end
end
