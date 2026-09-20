class Reviewer::ReviewerController < ApplicationController
    layout "reviewer"
    before_action :require_login
    before_action :require_reviewer
    before_action :set_nav

    private

    def set_nav
      @nav = "dashboard"
    end

    def require_reviewer
      unless current_user&.reviewer?
        redirect_to root_path, alert: "You do not have access to the reviewer dashboard."
      end
    end
end
