# Inherits the reviewer base rather than ApplicationController: every action in this
# namespace is for reviewers, and inheriting ApplicationController left this one
# reachable while signed out.
class Reviewer::UserController < Reviewer::ReviewerController
  before_action :set_user

  def show
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
