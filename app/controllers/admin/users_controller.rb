module Admin
  class UsersController < Admin::DashboardController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.order(:id)
    end

    def show
    end

    def edit
    end

    def update
      assign_role_if_allowed

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
      params.require(:user).permit(:name, :slack_id, :ysws_eligible, :verified, :credits)
    end

    def assign_role_if_allowed
      return unless current_user&.superadmin?

      requested_role = params.dig(:user, :role).to_s
      return if requested_role.blank?
      return unless User.roles.key?(requested_role)

      @user.role = requested_role
    end
  end
end
