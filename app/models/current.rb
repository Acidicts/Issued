# Current
# =======
# Current attributes class for thread-local current user context.
#
# Schema:
# - This is not a database table model, but a thread-local attributes store
# - hackclub_access_token: string (OAuth access token for current user)
# - hackclub_refresh_token: string (OAuth refresh token for current user)
#
# Relationships:
# - None (thread-local attributes, not database relationships)
#
# Validations:
# - None
#
# Enums:
# - None
#
# Attributes:
# - hackclub_access_token: string
# - hackclub_refresh_token: string
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
# Notes:
# - This class uses ActiveSupport::CurrentAttributes for thread-local storage
# - Used to store current user context across request lifecycle
# - Not a traditional ActiveRecord model with database table
#

class Current < ActiveSupport::CurrentAttributes
  attribute :hackclub_access_token, :hackclub_refresh_token
end
