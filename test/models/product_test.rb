require "test_helper"

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
    product = Product.new
    product.cost_gbp = "25.00"
    assert_equal "25.00", product.cost_gbp
  end
end
