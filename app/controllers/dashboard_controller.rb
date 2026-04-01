class DashboardController < ApplicationController
  layout "application"
  before_action :set_nav

  def index
    @user = current_user
    @orders = @user ? @user.orders : []
    @designs = Design.all
    @products = Product.all

    # Pipeline stuff needs doing
    @pipeline = [ 1, 2, 3, 4 ]
  end

  private

  def set_nav
    @nav = "dashboard"
  end
end
