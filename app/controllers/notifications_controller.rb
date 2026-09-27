class NotificationsController < ApplicationController
  layout "application"
  before_action :require_login

  def index
    @nav = "notifications"
    @notifications = current_user.notifications
    render "notifications/index"
  end

  def read
    @notification = current_user.notifications.find(params[:id])

    # `read` is overridden as a writer, so the attribute has to be read through the hash.
    if current_user == @notification.user && !@notification[:read]
      if @notification.is_a?(Notifications::BooleanNotification)
        @notification.yes_no = params[:boolean] if params[:boolean].present?
      elsif @notification.is_a?(Notifications::TextNotification)
        @notification.text = params[:text] if params[:text].present?
      end

      @notification.read
    end

    redirect_back fallback_location: root_path
  end
end
