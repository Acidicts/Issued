# == Schema Information
#
# Table name: orders
#
#  id          :bigint           not null, primary key
#  color_hex   :string
#  print_areas :jsonb            not null
#  status      :integer
#  step        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  product_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_orders_on_product_id  (product_id)
#  index_orders_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :product

  attribute :step, :integer, default: 3

  enum :status, { pending: 0, processing: 1, production: 2, completed: 3, cancelled: 4, user_cancelled: 5 }
  enum :step, { config: 0, design: 1, complete: 2, pending: 3 }, prefix: true

  attribute :color_hex, :string, default: ""
  attribute :print_areas, :json, default: {}

  has_many :order_print_areas, dependent: :destroy

  def build_print_areas_from_product
    return if print_areas.present?

    self.print_areas = product.print_areas.index_with(&:enabled?)
  end

  def active_print_area_names
    print_areas.select { |_, v| v }.keys
  end

  def total_cost_threads
    cost = self.product.thread_cost || 0
    cost += print_area_costs
    cost
  end

  def print_area_costs
    cost = 0
    product = self.product
    self.order_print_areas.each do |order_print_area|
      cost += product.print_areas.where(name: order_print_area.name).first.thread_cost
    end
    cost
  end

  def active_print_area?(name)
    print_areas[name] == true
  end

  def enable_print_area(name)
    print_areas[name] = true
  end

  def disable_print_area(name)
    print_areas[name] = false
  end

  def generate_and_attach_preview
    self.order_print_areas.each do |print_area|
      print_area.generate_and_attach_preview
    end
  end

  def user_cancel
    return unless current_user == user && pending?

    update(status: :user_cancelled)
  end

  def cancelled?
    self.status == "cancelled"
  end
end
