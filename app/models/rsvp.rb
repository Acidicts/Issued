# Rsvp
# =====
# Rsvp model representing user RSVP responses to events.
#
# Schema:
# - id: integer (primary key)
# - user_id: integer (foreign key to users)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :user (user who RSVP'd)
#
# Validations:
# - None
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
# Attachments:
# - None
#
# Scopes:
# - None
#
# Callbacks:
# - None
#

class Rsvp < ApplicationRecord
  belongs_to :user
end
