# DesignEditSession
# ==================
# Tracks user editing sessions for designs.
#
# Schema:
# - id: integer (primary key)
# - design_id: integer (foreign key to designs, not null)
# - user_id: integer (foreign key to users, not null)
# - started_at: datetime (not null)
# - ended_at: datetime
# - duration_seconds: integer (not null, default: 0)
# - activity_type: string (default: "edit")
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :design
# - belongs_to :user
#
# Validations:
# - duration_seconds: numericality (>= 0)
#
# Enums:
# - None
#
# Attributes:
# - None
#
# Methods:
# - None
#
# Scopes:
# - None
#
# Callbacks:
# - None
#

class DesignEditSession < ApplicationRecord
  belongs_to :design
  belongs_to :user

  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }
end
