# == Schema Information
#
# Table name: variants
#
#  id              :bigint           not null, primary key
#  color_hex       :string
#  cost            :integer
#  size            :integer
#  stock_by_region :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  printful_id     :integer
#  product_id      :bigint           not null
#
# Indexes
#
#  index_variants_on_product_id       (product_id)
#  index_variants_on_stock_by_region  (stock_by_region) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class Variant < ApplicationRecord
  belongs_to :product

  REGIONS = {
    "US"    => "United States",
    "EU"    => "Europe",
    "EU_LV" => "Latvia",
    "UK"    => "United Kingdom"
  }.freeze

  attribute :color_hex, default: ""
  attribute :stock_by_region, default: -> { {} }
  attribute :size
  enum :size, {
    "2XS": 0, "XS": 1, "S": 2, "M": 3, "L": 4,
    "XL": 5, "2XL": 6, "3XL": 7, "4XL": 8, "5XL": 9, "6XL": 10
  }

  validates :color_hex, format: { with: /\A#/ }, allow_blank: true
  validate :stock_by_region_keys_are_valid

  # true/false — is this variant in stock in the given region?
  def stock_for(region)
    ActiveModel::Type::Boolean.new.cast(stock_by_region[region.to_s])
  end

  def set_stock(region, in_stock)
    self.stock_by_region = stock_by_region.merge(
      region.to_s => ActiveModel::Type::Boolean.new.cast(in_stock)
    )
    save
  end

  def in_stock_in?(region)
    stock_for(region)
  end

  private

  def stock_by_region_keys_are_valid
    invalid = stock_by_region.keys - REGIONS.keys
    errors.add(:stock_by_region, "contains invalid regions: #{invalid.join(', ')}") if invalid.any?
  end
end
