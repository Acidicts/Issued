module Admin
  class DashboardController < ApplicationController
    layout "admin"
    before_action :require_login
    before_action :require_admin
    before_action :set_nav

    def index
      order_status_values = Order.statuses

      @orders_total = Order.count
      @orders_fulfilled = Order.where(status: order_status_values["completed"]).count
      @orders_pending = Order.where(status: order_status_values.values_at("pending", "processing", "production")).count

      @users_total = User.count
      @users_rsvps = Rsvp.distinct.count(:user_id)

      @highest_time_design = Design
        .select(:id, :name, :time, :hackatime_seconds)
        .order(Arel.sql("COALESCE(designs.time, 0) + COALESCE(designs.hackatime_seconds, 0) DESC"))
        .first
      @highest_time_seconds = @highest_time_design&.total_time_seconds.to_i
      @highest_time_formatted = format_duration(@highest_time_seconds)
    end

    private

    def format_duration(total_seconds)
      seconds = total_seconds.to_i
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      remaining_seconds = seconds % 60
      format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
    end

    def set_nav
      @nav = "dashboard"
    end

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "You do not have access to the admin dashboard."
      end
    end
  end
end
