# Base for the fufillment namespace: every action in this namespace is for fufillment
# staff, so inheriting ApplicationController would leave these pages reachable while
# signed out.
class Fufillment::FufillmentController < ApplicationController
  layout "fufillment"
  before_action :require_login
  before_action :require_fufillment
  before_action :set_nav

  def index
    redirect_to fufillment_batches_path
  end

  private

  def set_nav
    @nav = "dashboard"
  end

  def require_fufillment
    unless current_user&.fufillment?
      redirect_to root_path, alert: "You do not have access to the fufillment dashboard."
    end
  end
end
