require "test_helper"

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
class ProductTest < ActiveSupport::TestCase
  test "valid product" do
    product = Product.new(type: "T-Shirt", cost: 25, thread_cost: 50)
    assert product.valid?
  end

  test "has many orders" do
    product = products(:one)
    assert_respond_to product, :orders
  end

  test "cost attribute" do
    product = products(:one)
    assert_equal 1, product.cost
  end

  test "thread_cost defaults to zero" do
    product = Product.new
    assert_equal 0, product.thread_cost
  end

  test "type is disabled as inheritance column" do
    assert_equal "_type_disabled", Product.inheritance_column.to_s
  end

  test "has cost_gbp accessor" do
    product = Product.new(cost: 30)
    assert_respond_to product, :cost_gbp
  end
end
