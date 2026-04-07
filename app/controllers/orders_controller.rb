class OrdersController < ApplicationController
  before_action :require_login
  before_action :set_nav
  layout "application"

  def index
    @orders = current_user.orders
    render :index, layout: "application"
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
    redirect_to orders_path
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
  end

  def edit
    @order = Order.find(params[:id])
  end

  private

  def set_nav
    @nav = "dashboard"
  end
end
