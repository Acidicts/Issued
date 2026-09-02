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
    unless params[:product_id].present?
      redirect_to shop_path, alert: "Please select a product first."
      return
    end

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
    @print_area_configs = params[:order]&.dig(:print_area_configs) || {}
    if @print_area_configs.respond_to?(:to_unsafe_h)
      @print_area_configs = @print_area_configs.to_unsafe_h.transform_keys(&:to_s)
      @print_area_configs.each_value { |v| v.transform_keys!(&:to_s) if v.respond_to?(:transform_keys!) }
    end

    back_step = params[:back_step]
    @current_step = case back_step
    when "overview" then "overview"
    when "config" then "config"
    when "design" then "design"
    when "confirmation" then "confirmation"
    else
      if params[:print_area_nav] == "1"
        "design"
      else
        step = params[:step] || "overview"
        case step
        when "overview"
          "config"
        when "config"
          enabled_names = @product.print_areas.select { |pa| @order.print_areas[pa.name] == true }.map(&:name)
          params[:print_area] = enabled_names.first if params[:print_area].blank?
          "design"
        when "design"
          "confirmation"
        else
          "overview"
        end
      end
    end

    if @current_step == "confirmation"
      @design_images = {}
      @print_area_configs.each do |area_name, config|
        design = @designs.find { |d| d.id.to_s == config["design_id"].to_s }
        if design
          latest_image = design.images.order(created_at: :desc).first
          if latest_image&.image_file&.attached?
            @design_images[area_name.to_s] = url_for(latest_image.image_file)
          end
        end
      end
    end

    render partial: "orders/steps/#{@current_step}", formats: [ :html ]
  end

  def create
    @product = Product.find(params[:order][:product_id])
    @designs = current_user.designs.order(:name)
    @order = Order.new(order_params)
    @order.user = current_user
    @order.status = :pending
    @order.print_areas = build_print_areas_hash
    @order.build_print_areas_from_product

    print_area_configs = params[:order][:print_area_configs] || {}
    print_area_configs = print_area_configs.to_unsafe_h if print_area_configs.respond_to?(:to_unsafe_h)
    print_area_configs.each do |area_name, config|
      @order.order_print_areas.build(
        design_id: config["design_id"],
        x:         config["x"],
        y:         config["y"],
        xw:        config["wx"],
        yw:        config["wy"],
        rotation:  config["rotation"],
        name:      area_name.to_s,
      )
    end

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
    params.require(:order).permit(:product_id, :color_hex)
  end

  def build_print_areas_hash
    raw = params.dig(:order, :print_areas)
    return {} unless raw.present?

    raw.to_unsafe_h.transform_values { |v| v == "1" || v == "true" || v == true }
  end
end
