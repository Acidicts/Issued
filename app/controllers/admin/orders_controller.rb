module Admin
  class OrdersController < Admin::DashboardController
    before_action :require_admin
    def index
      @orders = Order.all
    end

    def show
      # Admin order details stub
    end

    def edit
      # Admin order edit / fulfillment stub
    end

    def update
      order = Order.find(params[:id])
      if order.update(order_params)
        redirect_to admin_orders_path, notice: "Order updated."
      else
        redirect_to admin_orders_path, alert: "Could not update order."
      end
    end

    def destroy
      # Admin delete order stub
    end

    def cancel
      order = Order.find(params[:id])
      if order.status != "cancelled" && order.status != :cancelled && order.status != "user_cancelled" && order.status != :user_cancelled
        order.status = :cancelled
        order.save
        flash[:notice] = "Order ##{order.id} has been cancelled."
      else
        flash[:alert] = "Order ##{order.id} is already cancelled."
      end
      redirect_to admin_orders_path
    end

    private

    def order_params
      params.require(:order).permit(:status)
    end
  end
end
