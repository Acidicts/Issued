class UserController < ApplicationController
  before_action :require_login, except: [ :show, :admin ]
  before_action :set_user

  def show
  end

  def admin
  end

  private
  def set_user
    @user = User.find(params[:id])
  end
end
