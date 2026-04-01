class OrdersController < ApplicationController
  def index
    @orders = current_user.orders
  end

  def show
    @order = Order.find(params[:id])
  end

  def new
    @order = Order.new
    @order.user = current_user
    @order.design = Design.find(params[:design_id])
    @order.status = :pending
    @order.product = Product.find(params[:product_id])
    @order.save
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
  end

  def edit
    @order = Order.find(params[:id])
  end
end
