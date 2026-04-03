class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  layout "application"

  before_action :set_current_oauth_tokens

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in?
    current_user.present?
  end

  private

  def set_current_oauth_tokens
    Current.hackclub_access_token = session[:hackclub_access_token]
    Current.hackclub_refresh_token = session[:hackclub_refresh_token]
  end

  def require_login
    unless signed_in?
      redirect_to root_path, alert: "You must be logged in to access this page."
    end
  end
end
