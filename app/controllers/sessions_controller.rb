require "net/http"
require "json"

class SessionsController < ApplicationController
  HACKCLUB_AUTHORIZE_URL = "https://auth.hackclub.com/oauth/authorize"
  HACKCLUB_TOKEN_URL = "https://auth.hackclub.com/oauth/token"
  HACKCLUB_ME_URL = "https://auth.hackclub.com/api/v1/me"

  def new
    session[:return_to] = safe_redirect_path(params[:redirect]) if params[:redirect].present?

    unless client_id.present? && client_secret.present?
      flash[:alert] = "Hack Club OAuth is not configured. Set HACKCLUB_CLIENT_ID and HACKCLUB_CLIENT_SECRET."
      redirect_to root_path
      return
    end

    redirect_to hackclub_authorization_url, allow_other_host: true
  end

  def callback
    code = params[:code].to_s.strip

    if code.blank?
      redirect_to root_path, alert: "Authorization code missing from Hack Club callback"
      return
    end

    token_data = exchange_code_for_token(code)
    profile = fetch_hackclub_me(token_data.fetch("access_token"))

    slack_id = profile["slack_id"].presence || profile["id"].presence
    user = if slack_id
      User.find_or_initialize_by(slack_id: slack_id)
    else
      User.new
    end

    user.name = profile["name"] || profile["nickname"] || profile["email"]
    user.verified = (profile["verification_status"] || profile["verified"]).to_i
    user.ysws_eligible = ActiveModel::Type::Boolean.new.cast(
      profile["ysws_eligible"] || profile["yws_eligible"] || profile["yws_eligible?"]
    )
    user.ysws_eligible = false if user.ysws_eligible.nil?
    user.slack_id = slack_id if slack_id
    user.save!

    session[:user_id] = user.id
    session[:hackclub_access_token] = token_data["access_token"]
    session[:hackclub_refresh_token] = token_data["refresh_token"] if token_data["refresh_token"]

    redirect_path = safe_redirect_path(session.delete(:return_to)) || safe_redirect_path(params[:redirect]) || root_path
    redirect_to redirect_path, notice: "Welcome #{user.name || user.slack_id}!"
  rescue StandardError => e
    logger.error("Hack Club OAuth callback failed: #{e.class} #{e.message}")
    redirect_to root_path, alert: "Unable to sign in via Hack Club. Please try again."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out"
  end

  private

  def client_id
    ENV["HACKCLUB_CLIENT_ID"].presence || raise("HACKCLUB_CLIENT_ID is not configured")
  end

  def client_secret
    ENV["HACKCLUB_CLIENT_SECRET"].presence || raise("HACKCLUB_CLIENT_SECRET is not configured")
  end

  def callback_url
    ENV["HACKCLUB_REDIRECT_URI"].presence || hackclub_callback_url
  end

  def hackclub_authorization_url
    query = {
      client_id: client_id,
      redirect_uri: callback_url,
      response_type: "code",
      scope: "openid profile email name slack_id verification_status"
    }

    "#{HACKCLUB_AUTHORIZE_URL}?#{URI.encode_www_form(query)}"
  end

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

  def exchange_code_for_token(code)
    uri = URI(HACKCLUB_TOKEN_URL)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: callback_url,
      code: code,
      grant_type: "authorization_code"
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Token exchange failed with status #{response.code}"
    end

    JSON.parse(response.body)
  end

  def fetch_hackclub_me(access_token)
    uri = URI(HACKCLUB_ME_URL)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to fetch hackclub profile: #{response.code}"
    end

    JSON.parse(response.body)
  end
end
