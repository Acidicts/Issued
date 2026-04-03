class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }

  enum :role, { user: 0, admin: 1, superadmin: 2 }, default: :user

  def admin?
    role == "admin" || role == "superadmin"
  end

  def refresh_ysws_eligibility!
    info = fetch_live_hackclub_identity
    return false unless info.present?

    update_ysws_eligibility_from_auth_info(info)
    save!(validate: false) if changed?
  end

  def update_ysws_eligibility_from_auth_info(info)
    self.ysws_eligible = ActiveModel::Type::Boolean.new.cast(
      info["ysws_eligible"] || info[:ysws_eligible] || info["yws_eligible"] || info[:yws_eligible] || info["yws_eligible?"] || info[:"yws_eligible?"]
    )
    self.ysws_eligible = false if ysws_eligible.nil?
  end

  private

  def fetch_live_hackclub_identity
    return unless Current.hackclub_access_token.present?

    response = hackclub_access_token.get("/api/v1/me")
    info = response.parsed
    info = info["identity"] if info.is_a?(Hash) && info["identity"].present?
    info
  rescue OAuth2::Error => error
    if error.response.status == 401 && Current.hackclub_refresh_token.present?
      refresh_hackclub_access_token!
      retry
    end
    Rails.logger.error("Hack Club info refresh failed: #{error.message}")
    nil
  end

  def hackclub_oauth_client
    OAuth2::Client.new(
      ENV.fetch("HACKCLUB_CLIENT_ID", ""),
      ENV.fetch("HACKCLUB_CLIENT_SECRET", ""),
      site: "https://auth.hackclub.com",
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/token"
    )
  end

  def hackclub_access_token
    OAuth2::AccessToken.new(
      hackclub_oauth_client,
      Current.hackclub_access_token,
      refresh_token: Current.hackclub_refresh_token
    )
  end

  def refresh_hackclub_access_token!
    new_token = hackclub_access_token.refresh!
    Current.hackclub_access_token = new_token.token
    Current.hackclub_refresh_token = new_token.refresh_token if new_token.refresh_token.present?
  end
end
