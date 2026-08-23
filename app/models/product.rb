# == Schema Information
#
# Table name: products
#
#  id          :bigint           not null, primary key
#  cost        :integer
#  description :text
#  image_wx    :integer          default(0), not null
#  image_wy    :integer          default(0), not null
#  image_x     :integer          default(0), not null
#  image_y     :integer          default(0), not null
#  thread_cost :integer          default(0)
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Product < ApplicationRecord
  include CurrencyConvertible

  self.inheritance_column = :_type_disabled

  has_one_attached :image
  has_many :orders, dependent: :destroy
  has_many :variants, dependent: :destroy
  accepts_nested_attributes_for :variants, allow_destroy: true

  attribute :description, default: "", null: false

  def cost_usd
    self.cost
  end

  def cost_gbp
    usd_to_gbp(self.cost)
  end
end
