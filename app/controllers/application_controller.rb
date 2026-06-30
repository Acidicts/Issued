class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?, :unread_notification_count, :current_maker

  layout "application"

  before_action :set_current_oauth_tokens
  before_action :set_nav
  before_action :current_url
  before_action :current_path
  before_action :current_threads

  BARCODE_WIDTHS = [
    2, 1, 1, # Start B
    1, 4, 2, # I
    1, 4, 2, # S
    1, 4, 2, # S
    3, 2, 1, # U
    2, 3, 1, # E
    2, 1, 3, # D
    2, 3, 2, # Checksum (Value 30)
    2, 3, 1, 2 # Stop Pattern
  ].freeze

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_url
    @current_url = request.original_url
  end

  def current_path
    @current_path = request.path
  end

  def signed_in?
    current_user.present?
  end

  def current_maker
    return unless signed_in?
    {
      id: current_user.id.to_s.rjust(4, "0"),
      name: current_user.name
    }
  end

  def current_threads
    return unless signed_in?
    @threads = current_user.threads || 0
  end

  def unread_notification_count
    0
  end

  private
  def set_nav
    @nav = "home"
  end

  def set_current_oauth_tokens
    Current.hackclub_access_token = session[:hackclub_access_token]
    Current.hackclub_refresh_token = session[:hackclub_refresh_token]

    return unless current_user
    return if session[:hackclub_access_token].blank? && session[:hackclub_refresh_token].blank?
    return unless current_user.respond_to?(:hackclub_access_token) && current_user.respond_to?(:hackclub_refresh_token)
    return unless current_user.respond_to?(:hackclub_access_token=) && current_user.respond_to?(:hackclub_refresh_token=)

    needs_access_update = session[:hackclub_access_token].present? && current_user.hackclub_access_token != session[:hackclub_access_token]
    needs_refresh_update = session[:hackclub_refresh_token].present? && current_user.hackclub_refresh_token != session[:hackclub_refresh_token]
    return unless needs_access_update || needs_refresh_update

    current_user.hackclub_access_token = session[:hackclub_access_token] if needs_access_update
    current_user.hackclub_refresh_token = session[:hackclub_refresh_token] if needs_refresh_update
    current_user.save!(validate: false)
  end

  def require_login
    unless signed_in?
      redirect_to root_path, alert: "You must be logged in to access this page."
    end
  end
end
