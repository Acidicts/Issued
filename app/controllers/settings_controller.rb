class SettingsController < ApplicationController
  before_action :require_login
  layout "application"

  def index
  end
end
