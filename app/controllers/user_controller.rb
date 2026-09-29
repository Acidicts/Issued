class UserController < ApplicationController
  before_action :require_login, except: [ :show ]
  before_action :set_user

  def show
  end

  def admin
  end

  def reviewer
  end

  private
  def set_user
    @user = User.find_by(id: params[:id])
  end
end
