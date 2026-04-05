class DashboardController < ApplicationController
  layout "application"
  before_action :set_nav
  before_action :require_login

  def index
    @user = current_user
    @orders = @user ? @user.orders : []
    @designs = current_user.designs
    @products = Product.all

    # Hackatime integration
    if @user&.slack_id.present? && HackatimeService.available?
      service = HackatimeService.new(slack_id: @user.slack_id)
      @hackatime_projects = service.get_all_projects
      @hackatime_trust = service.get_trusted_status
    else
      @hackatime_projects = []
      @hackatime_trust = nil
    end

    # Pipeline stuff needs doing
    orders = @user.orders.includes(:design, :product)
    @pipeline = [ orders.where(status: :pending).count, orders.where(status: :processing).count, orders.where(status: :production).count, orders.where(status: :completed).count ]
  end

  private

  def set_nav
    @nav = "dashboard"
  end
end
