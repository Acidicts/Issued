require "test_helper"
require "securerandom"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      slack_id: "UADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :admin
    )
    sign_in_as(@admin)
  end

  test "admin can list products" do
    get admin_products_url
    assert_response :success
  end

  test "admin can view new product form" do
    get new_admin_product_url
    assert_response :success
  end

  test "admin can create product" do
    assert_difference("Product.count", 1) do
      post admin_products_url, params: {
        product: { type: "Sticker", cost: 10, thread_cost: 25 }
      }
    end
    assert_redirected_to admin_product_url(Product.last)
  end

  test "admin can edit product" do
    product = products(:one)
    get edit_admin_product_url(product)
    assert_response :success
  end

  test "admin can update product" do
    product = products(:one)
    patch admin_product_url(product), params: {
      product: { type: "Updated Shirt", cost: 30 }
    }
    assert_redirected_to admin_product_url(product)
    assert_equal "Updated Shirt", product.reload.type
  end

  test "admin can delete product without orders" do
    product = Product.create!(type: "Delete Me", cost: 5, thread_cost: 0)

    assert_difference("Product.count", -1) do
      delete admin_product_url(product)
    end
    assert_redirected_to admin_products_url
  end

  test "non-admin cannot access products" do
    non_admin = User.create!(
      name: "Regular User",
      slack_id: "UNONADMIN#{SecureRandom.hex(4)}",
      veri_level: :verified,
      ysws_eligible: false,
      role: :user
    )
    sign_in_as(non_admin)

    get admin_products_url
    assert_redirected_to root_url
  end
end
