module AuthorizationConcern
  extend ActiveSupport::Concern

  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "You do not have access to the admin dashboard."
    end
  end

  def require_owner(resource)
    return if resource.user == current_user || current_user&.admin?

    redirect_to root_path, alert: "You are not authorized to perform this action."
  end
end
