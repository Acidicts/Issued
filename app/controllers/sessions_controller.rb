require "cgi"
require "uri"

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def new
    unless ENV["HACKCLUB_CLIENT_ID"].present? && ENV["HACKCLUB_CLIENT_SECRET"].present?
      flash[:alert] = "Hack Club OAuth is not configured. Set HACKCLUB_CLIENT_ID and HACKCLUB_CLIENT_SECRET."
      redirect_to root_path
      return
    end

    if params[:redirect].present? && params[:redirect] == "/"
      session[:return_to] = "/dashboard"
    else
      session[:return_to] = safe_redirect_path(params[:redirect]) if params[:redirect].present?
    end

    auth_path = "/auth/hackclub"
    origin = safe_redirect_path(session[:return_to])
    auth_path += "?origin=#{CGI.escape(origin)}" if origin.present?
    redirect_to auth_path
  end

  def create
    auth = request.env["omniauth.auth"]
    if auth.blank?
      redirect_to root_path, alert: "Authentication data missing from OAuth callback"
      return
    end

    info = auth.info
    slack_id = info["slack_id"].presence || info[:slack_id].presence || auth.uid.presence
    user = if slack_id
      User.find_or_initialize_by(slack_id: slack_id)
    else
      User.new
    end

    user.name = info["name"] || info[:name] || info["nickname"] || info[:nickname] || info["email"] || info[:email]
    user.verified = ActiveModel::Type::Boolean.new.cast(
      info["verification_status"] || info[:verification_status] || info["verified"] || info[:verified]
    )
    user.update_ysws_eligibility_from_auth_info(info)
    user.slack_id = slack_id if slack_id
    user.save!

    session[:user_id] = user.id
    if auth.credentials
      session[:hackclub_access_token] = auth.credentials.token if auth.credentials.token.present?
      session[:hackclub_refresh_token] = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      Current.hackclub_access_token = session[:hackclub_access_token]
      Current.hackclub_refresh_token = session[:hackclub_refresh_token]
      begin
        user.refresh_ysws_eligibility!
      rescue StandardError => e
        logger.warn("Skipping Hack Club profile refresh: #{e.class} #{e.message}")
      end
    end

    redirect_path = safe_redirect_path(request.env["omniauth.origin"]) || safe_redirect_path(session.delete(:return_to)) || safe_redirect_path(params[:origin]) || root_path
    redirect_to redirect_path, notice: "Welcome #{user.name || user.slack_id}!"
  rescue StandardError => e
    logger.error("Hack Club OAuth callback failed: #{e.class} #{e.message}")
    redirect_to root_path, alert: "Unable to sign in via Hack Club. Please try again."
  end

  def failure
    reason = params[:message].presence || request.env.dig("omniauth.error", "error") || request.env.dig("omniauth.error", "error_reason") || "Unknown error"
    logger.warn("OmniAuth failure: #{reason}")
    redirect_to root_path, alert: "Authentication failed: #{reason}"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out"
  end

  private

  def safe_redirect_path(path)
    return nil unless path.present?

    parsed = URI.parse(path) rescue nil
    return nil unless parsed

    if parsed.scheme.nil? && parsed.host.nil? && parsed.path.present? && parsed.path.start_with?("/")
      result = parsed.path
      result += "?#{parsed.query}" if parsed.query.present?
      result
    else
      nil
    end
  end
end
