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
    @product = Product.find(params[:product_id])
    @designs = current_user.designs.includes(images: :image_file_attachment)
    @order = Order.new(product: @product)
  end

  def create
    @product = Product.find(params[:order][:product_id])
    @designs = current_user.designs.order(:name)
    @order = Order.new(order_params)
    @order.user = current_user
    @order.status = :pending
    @order.generate_and_attach_preview

    if @order.save
      redirect_to orders_path, notice: "Order placed successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @order = Order.find(params[:id])
  end

  def update
    @order = Order.find(params[:id])
    if @order.update(order_params)
      redirect_to orders_path, notice: "Order updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order = Order.find(params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Order cancelled."
  end

  private

  def set_nav
    @nav = "dashboard"
  end

  def order_params
    params.require(:order).permit(:design_id, :product_id, :x, :y, :wx, :wy, :rotation)
  end
end
