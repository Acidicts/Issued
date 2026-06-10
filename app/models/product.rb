# Product
# =======
# Product model representing items available for purchase.
#
# Schema:
# - id: integer (primary key)
# - type: string (product type)
# - cost: decimal (product cost)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - has_one_attached :image (ActiveStorage attachment)
# - has_many :orders (orders for this product)
#
# Validations:
# - None
#
# Enums:
# - None
#
# Attributes:
# - cost_gbp: string (virtual attribute for GBP cost display)
#
# Methods:
# - None
#
# Attachments:
# - image: ActiveStorage attachment for product image
#
# Scopes:
# - None
#
# Callbacks:
# - None
#

class Product < ApplicationRecord
  self.inheritance_column = :_type_disabled

  attr_accessor :cost_gbp

  has_one_attached :image
  has_many :orders
end
