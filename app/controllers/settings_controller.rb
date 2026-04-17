class SettingsController < ApplicationController
  before_action :require_login
  layout "application"

  def index
  end

  private
  def set_nav
    @nav = "dashboard"
  end
end
