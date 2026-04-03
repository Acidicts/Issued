module Admin
  class UsersController < Admin::DashboardController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      User.all.each do |user|
        user.validate
      end
      @users = User.order(:id)
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User updated successfully."
      else
        flash.now[:alert] = "Unable to update user. Please fix the errors and try again."
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :slack_id, :role, :ysws_eligible, :verified, :credits)
    end
  end
end
