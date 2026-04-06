class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }

  enum :role, { user: 0, admin: 1, superadmin: 2 }, prefix: :role, default: :user
  attribute :trust, :integer
  enum :trust, { unknown: 0, red: 1, yellow: 2, blue: 3, green: 4 }, default: :unknown
  attribute :veri_level, :integer
  enum :veri_level, { unknown: 0, needs_submission: 1, pending: 2, verified: 3, ineligible: 4 }, prefix: :veri_level, default: :unknown

  validate :trust_level_correct
  validate :update_veri_level

  def trust_level_correct
    t = get_trusted_status(slack_id: slack_id)
    if t.present?
      t = t.is_a?(Array) ? t[0] : t
      self.trust = t if t.present?
    end

    self.trust ||= :unknown
    save!(validate: false) if persisted? && saved_change_to_attribute?(:trust)
  end

  def update_veri_level
    info = fetch_live_hackclub_identity
    return unless info.present?

    new_level = info["verification_status"]
    new_level_key = self.class.veri_levels[new_level]
    return unless new_level_key.present?

    if veri_level != new_level
      self.veri_level = new_level_key
      save!(validate: false) if persisted?
    end
  end

  def verified_for_ysws?
    veri = self.veri_level == "verified"
    trus = self.trust.in?(%w[blue green])
    veri && trus && ysws_eligible
  end

  def admin?
    role == "admin" || role == "superadmin"
  end

  def refresh_ysws_eligibility!
    info = fetch_live_hackclub_identity
    return false unless info.present?

    update_ysws_eligibility_from_auth_info(info)
    save!(validate: false) if changed?
  end

  def fetch_live_hackclub_oauth_info(access_token: nil, refresh_token: nil)
    stored_token   = has_attribute?(:hackclub_access_token)  ? hackclub_access_token  : nil
    stored_refresh = has_attribute?(:hackclub_refresh_token) ? hackclub_refresh_token : nil
    token_value   = access_token.presence   || Current.hackclub_access_token.presence   || stored_token.presence   || ENV["HACKCLUB_ACCESS_TOKEN"].presence
    refresh_value = refresh_token.presence  || Current.hackclub_refresh_token.presence  || stored_refresh.presence || ENV["HACKCLUB_REFRESH_TOKEN"].presence
    return unless token_value.present?

    response = hackclub_oauth_access_token(token: token_value, refresh_token: refresh_value).get("/api/v1/me")
    response.parsed
  rescue OAuth2::Error => error
    if error.response.status == 401 && refresh_value.present?
      token_value, refresh_value = refresh_hackclub_access_token!(token: token_value, refresh_token: refresh_value)
      retry
    end
    Rails.logger.error("Hack Club OAuth info fetch failed: #{error.message}")
    nil
  end

  def update_ysws_eligibility_from_auth_info(info)
    self.ysws_eligible = ActiveModel::Type::Boolean.new.cast(
      info["ysws_eligible"] || info[:ysws_eligible] || info["yws_eligible"] || info[:yws_eligible] || info["yws_eligible?"] || info[:"yws_eligible?"]
    )
    self.ysws_eligible = false if ysws_eligible.nil?
  end

  private

  def fetch_live_hackclub_identity
    info = fetch_live_hackclub_oauth_info
    info = info["identity"] if info.is_a?(Hash) && info["identity"].present?
    info
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

  def hackclub_oauth_access_token(token: Current.hackclub_access_token, refresh_token: Current.hackclub_refresh_token)
    OAuth2::AccessToken.new(
      hackclub_oauth_client,
      token,
      refresh_token: refresh_token
    )
  end

  def get_trusted_status(slack_id: nil)
    return nil unless slack_id.present?

    # Always fetch live data from Hackatime instead of using request-level caching
    Rails.logger.info "Admin::UsersHelper#get_trusted_status: fetching live trust for #{slack_id}"
    service_result = HackatimeService.new(slack_id: slack_id).get_trusted_status

    # Support structured Hash result or scalar and return the live trust_level when possible
    if service_result.is_a?(Hash)
      level = service_result[:trust_level] || service_result["trust_level"]
      value = service_result[:trust_value] || service_result["trust_value"]

      # Prefer string trust_level (e.g. "blue", "verified"); fall back to numeric trust_value
      [ level, value ]
    else
      service_result
    end
  rescue => e
    Rails.logger.error "Admin::UsersHelper#get_trusted_status error: #{e.message}"
    nil
  end

  def refresh_hackclub_access_token!(token: Current.hackclub_access_token, refresh_token: Current.hackclub_refresh_token)
    new_token = hackclub_oauth_access_token(token: token, refresh_token: refresh_token).refresh!
    Current.hackclub_access_token = new_token.token
    Current.hackclub_refresh_token = new_token.refresh_token if new_token.refresh_token.present?

    self.hackclub_access_token = Current.hackclub_access_token
    if Current.hackclub_refresh_token.present?
      self.hackclub_refresh_token = Current.hackclub_refresh_token
    end
    save!(validate: false) if persisted? && changed?

    [ Current.hackclub_access_token, Current.hackclub_refresh_token ]
  end
end
