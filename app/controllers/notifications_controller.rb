class NotificationsController < ApplicationController
  before_action :require_login

  def index
    # Replace with current_maker.notifications.order(created_at: :desc) once the
    # Notification model exists — demo data below keeps the view renderable on its own.
    @notifications = current_user.notifications
  end

  def read
    notification = Notification.find(params[:id])
    return unless current_user == notification.user
    notification.read
    redirect_back(fallback_location: root_path)
  end
end
