class ShopController < ApplicationController
  layout "application"
  before_action :set_nav

  def index
    @products = Product.all.order(:type)
  end

  private

  def set_nav
    @nav = "shop"
  end
end
