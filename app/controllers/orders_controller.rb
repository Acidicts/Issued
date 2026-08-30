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
    redirect_to root_path unless current_user == @order.user || current_user.admin?
  end

  def new
    @product = Product.find(params[:product_id])
    @designs = current_user.designs.includes(images: :image_file_attachment)
    @order = Order.new(product: @product)
    render :new
  end

  def new_step
    product_id = params[:order][:product_id] || params[:product_id]
    @product = Product.find(product_id)
    @designs = current_user.designs.includes(images: :image_file_attachment)
    @order = Order.new(product: @product, color_hex: params[:order][:color_hex] || params[:color_hex])
    @order.print_areas = build_print_areas_hash
    @order_params = params[:order]

    if params[:back_step]
      @current_step = params[:back_step]
    else
      step = params[:step] || "overview"
      case step
      when "overview"
        @current_step = "config"
      when "config"
        @current_step = "design"
      when "design"
        @current_step = "confirmation"
      else
        @current_step = "overview"
      end
    end

    render partial: "orders/steps/#{@current_step}", formats: [:html]
  end

  def create
    @product = Product.find(params[:order][:product_id])
    @designs = current_user.designs.order(:name)
    @order = Order.new(order_params)
    @order.user = current_user
    @order.status = :pending
    @order.print_areas = build_print_areas_hash
    @order.build_print_areas_from_product

    @order.order_print_areas.build(
      design_id: params[:order][:design_id],
      x:         params[:order][:x],
      y:         params[:order][:y],
      xw:        params[:order][:wx],
      yw:        params[:order][:wy],
      rotation:  params[:order][:rotation],
    )

    @order.generate_and_attach_preview

    if @order.save
      redirect_to orders_path, notice: "Order placed successfully!"
    else
      @current_step = "design"
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

  def cancel
    order = Order.find(params[:id])
    return unless order.user == current_user || current_user.admin?

    order.status = :user_cancelled
    order.save!

    render partial: "orders/status_pill", locals: { order: order }
  end

  private

  def set_nav
    @nav = "dashboard"
  end

  def order_params
    params.require(:order).permit(:product_id, :color_hex, :design_id, :x, :y, :wx, :wy, :rotation)
  end

  def build_print_areas_hash
    raw = params[:order][:print_areas]
    return {} unless raw.is_a?(Hash)

    raw.transform_values { |v| v == "1" || v == "true" || v == true }
  end
end
