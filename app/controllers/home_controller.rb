class HomeController < ApplicationController
  before_action :set_nav

  def index
    @nav = nil
  end

  def about
  end

  def faq
  end

  private
  def set_nav
    @nav = "home"
  end
end
