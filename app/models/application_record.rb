# ApplicationRecord
# ============
# Base ActiveRecord model class for all application models.
# This is an abstract class that provides the foundation for all other models.
#
# Schema:
# - No database fields (abstract class)
# - Inherits from ActiveRecord::Base
# - Used as the base class for all other models in the application
#
# Relationships:
# - All models inherit from this class
#
# Validations:
# - None (abstract class)
#
# Methods:
# - None (abstract class)
#
# Enums:
# - None (abstract class)
#
# Attributes:
# - None (abstract class)
#
# Attachments:
# - None (abstract class)
#
# Scopes:
# - None (abstract class)
#
# Callbacks:
# - None (abstract class)
#
# Notes:
# - This is an abstract class and should not be instantiated directly
# - All other models inherit from this class
#

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
