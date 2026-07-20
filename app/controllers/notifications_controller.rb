class NotificationsController < ApplicationController
  layout "application"
  before_action :require_login

  def index
    @nav = "notifications"
    @notifications = current_user.notifications
    render "notifications/index"
  end

  def read
    notification = Notification.find(params[:id])
    return unless current_user == notification.user
    notification.read
    redirect_back(fallback_location: root_path)
  end
end
