# DesignEditSession
# =================
# DesignEditSession model representing sessions of editing a design.
#
# Schema:
# - id: integer (primary key)
# - design_id: integer (foreign key to designs)
# - user_id: integer (foreign key to users)
# - started_at: datetime (session start time)
# - ended_at: datetime (session end time, nullable)
# - duration_seconds: integer (session duration in seconds)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :design (design being edited)
# - belongs_to :user (user who edited the design)
#
# Validations:
# - started_at: presence validation
# - duration_seconds: numericality validation (>= 0)
#
# Enums:
# - None
#
# Attributes:
# - None
#
# Methods:
# - ended?: Checks if session has ended (ended_at present)
#
# Attachments:
# - None
#
# Scopes:
# - recent: Scope to get recent edit sessions ordered by started_at descending
#
# Callbacks:
# - None
#

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
