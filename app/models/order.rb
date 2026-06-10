# Order
# =====
# Order model representing user purchases of products and designs.
#
# Schema:
# - id: integer (primary key)
# - user_id: integer (foreign key to users)
# - design_id: integer (foreign key to designs, nullable)
# - product_id: integer (foreign key to products)
# - status: integer (order status: 0=pending, 1=processing, 2=production, 3=completed, 4=cancelled, 5=user_cancelled)
# - created_at: datetime
# - updated_at: datetime
#
# Relationships:
# - belongs_to :user (user who placed the order)
# - belongs_to :design (design associated with the order, nullable)
# - belongs_to :product (product being ordered)
#
# Validations:
# - None
#
# Enums:
# - status: { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }
#
# Attributes:
# - None
#
# Methods:
# - user_cancel: Cancels order if user is current user and order is pending
# - cancelled?: Checks if order is cancelled (has bug - calls itself recursively)
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

class Order < ApplicationRecord
  belongs_to :user
  belongs_to :design
  belongs_to :product

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }

  def user_cancel
    return unless current_user == user && pending?

    update(status: :user_cancelled)
  end

  def cancelled?
    cancelled? || user_cancelled?
  end
end
