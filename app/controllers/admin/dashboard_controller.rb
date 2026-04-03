module Admin
  class DashboardController < ApplicationController
    layout "admin"
    before_action :require_login
    before_action :require_admin
    before_action :set_nav

    def index
      # Admin overview / metrics dashboard stub
    end

    private

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
