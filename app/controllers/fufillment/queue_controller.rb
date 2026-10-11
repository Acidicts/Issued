class Fufillment::QueueController < Fufillment::FufillmentController
  PER_PAGE = 50

  before_action :set_order, only: %i[show edit update]

  def index
    @page = [ params[:page].to_i, 0 ].max

    @orders = queue_scope
      .order(:id)
      .limit(PER_PAGE)
      .offset(@page * PER_PAGE)
  end

  def show
    @addresses = HackclubAuthService.new(@order.user).get_user_addresses
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to fufillment_queue_index_path, notice: "Order updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def queue_scope
    Order
      .joins(:batch)
      .where(status: :pending, batches: { status: :being_fufilled })
      .includes(:product, order_print_areas: [:design, { preview_image_attachment: :blob }])
  end

  def set_order
    @order = Order
      .includes(:user, :batch, :product, order_print_areas: [:design, { preview_image_attachment: :blob }])
      .find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status)
  end
end
