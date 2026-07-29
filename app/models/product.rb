# Product
# =======
# Product model representing items available for purchase.
#
# Schema:
# - id: integer (primary key)
# - type: string (product type)
# - description: text (product description)
# - cost: decimal (product cost_usd)
# - thread_cost: integer (product thread_cost)
# - created_at: datetime
# - updated_at: datetime
# - image_x: integer (for order preview etc) in px
# - image_y: integer (for order preview etc) in px
# - image_wx: integer (for order preview etc) in px
# - image_wy: integer (for order preview etc) in px
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
  include CurrencyConvertible

  self.inheritance_column = :_type_disabled

  has_one_attached :image
  has_many :orders

  attribute :description, default: "", null: false

  def cost_usd
    self.cost
  end

  def cost_gbp
    usd_to_gbp(self.cost)
  end
end
