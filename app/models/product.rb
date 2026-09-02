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
#  printful_id :integer
#
class Product < ApplicationRecord
  include CurrencyConvertible

  self.inheritance_column = :_type_disabled

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end
  has_many :orders, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :print_areas, dependent: :destroy

  accepts_nested_attributes_for :variants, allow_destroy: true

  attribute :description, default: "", null: false
  attribute :printful_id, default: nil, null: true

  REGIONS = {
    "US"    => "United States",
    "EU"    => "Europe",
    "EU_LV" => "Latvia",
    "UK"    => "United Kingdom"
  }.freeze

  def cost_usd
    self.cost
  end

  def cost_gbp
    usd_to_gbp(self.cost)
  end

  def check_stock
    data = PrintfulService.check_variants_stock(self.printful_id)
    printful_ids = variants.pluck(:printful_id)
    data[:variants].each do |variant|
      variant_obj = variants.find { |v| v.printful_id == variant["id"] }
      next unless variant_obj

      Array(variant["availability_status"]).each do |entry|
        region = entry["region"]
        status = entry["status"]
        next unless REGIONS.key?(region)

        variant_obj.set_stock(region, status == "in_stock")
      end
    end
  end
end
