require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "valid order" do
    order = Order.new(user: users(:one), design: designs(:one), product: products(:one), status: :pending)
    assert order.valid?
  end

  test "belongs to user" do
    order = orders(:one)
    assert_equal users(:one), order.user
  end

  test "belongs to design" do
    order = orders(:one)
    assert_equal designs(:one), order.design
  end

  test "belongs to product" do
    order = orders(:one)
    assert_equal products(:one), order.product
  end

  test "status enum values" do
    order = orders(:one)
    assert_equal "processing", order.status

    order.status = :pending
    assert_equal "pending", order.status

    order.status = :completed
    assert_equal "completed", order.status

    order.status = :cancelled
    assert_equal "cancelled", order.status

    order.status = :user_cancelled
    assert_equal "user_cancelled", order.status
  end

  test "order has a valid user" do
    order = orders(:one)
    assert order.user.persisted?
  end

  test "order has a valid design" do
    order = orders(:one)
    assert order.design.persisted?
  end

  test "order has a valid product" do
    order = orders(:one)
    assert order.product.persisted?
  end
end
