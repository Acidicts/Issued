require "test_helper"

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
class VariantTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
