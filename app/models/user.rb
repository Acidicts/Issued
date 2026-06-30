# User
# =====
# User model representing application users with authentication, verification, and role-based access.
#
# Schema:
# - email: string (from Hack Club identity)
# - id: integer (primary key)
# - name: string (from Hack Club identity)
# - slack_id: string (from Hack Club identity)
# - ysws_eligible: boolean (YSWS eligibility status)
# - role: integer (user role: 0=user, 1=admin, 2=superadmin, 3=reviewer)
# - veri_level: integer (verification level: 0=unknown, 1=needs_submission, 2=pending, 3=verified, 4=ineligible)
# - hackclub_access_token: string (OAuth access token)
# - hackclub_refresh_token: string (OAuth refresh token)
# - threads: integer
#
# Relationships:
# - has_many :designs (dependent: :destroy)
# - has_many :orders (dependent: :destroy)
#
# Validations:
# - ysws_eligible: inclusion in [true, false]
#
# Enums:
# - role: { user: 0, admin: 1, superadmin: 2, reviewer: 3 }
# - veri_level: { unknown: 0, needs_submission: 1, pending: 2, verified: 3, ineligible: 4 }
#
# Attributes:
# - veri_level: integer
#
# Methods:
# - verified_for_ysws?: Checks if user is verified for YSWs
# - admin?: Checks if user has admin privileges
# - refresh_ysws_eligibility!: Refreshes YSWs eligibility and verification from Hack Club
# - fetch_live_hackclub_oauth_info: Fetches user identity from Hack Club OAuth
# - update_ysws_eligibility_from_auth_info: Updates YSWs eligibility from auth info
# - fetch_live_hackclub_identity: Fetches user identity from Hack Club
# - hackclub_oauth_client: Creates OAuth client for Hack Club
# - hackclub_oauth_access_token: Creates OAuth access token
# - refresh_hackclub_access_token!: Refreshes OAuth access token
#
# Attachments:
# - None
#
# Scopes:
# - None
#
# Callbacks:
# - None
#

class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }

  enum :role, { user: 0, admin: 1, superadmin: 2, reviewer: 3 }, prefix: :role, default: :user
  attribute :veri_level, :integer
  attribute :email, :string
  attribute :threads, :integer, default: 0
  enum :veri_level, { unknown: 0, needs_submission: 1, pending: 2, verified: 3, ineligible: 4 }, prefix: :veri_level, default: :unknown

  attribute :credits, default: 0, nil: false

  def verified_for_ysws?
    veri_level == "verified" && ysws_eligible
  end

  def admin?
    role == "admin" || role == "superadmin" || role == "reviewer"
  end

  def refresh_ysws_eligibility!
    info = fetch_live_hackclub_identity
    return false unless info.present?

    update_ysws_eligibility_from_auth_info(info)

    status = info["verification_status"]
    if status.present? && self.class.veri_levels.key?(status)
      self.veri_level = self.class.veri_levels[status]
    end

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

  def refresh_hackclub_access_token!(token: Current.hackclub_access_token, refresh_token: Current.hackclub_refresh_token)
    new_token = hackclub_oauth_access_token(token: token, refresh_token: refresh_token).refresh!
    Current.hackclub_access_token = new_token.token
    Current.hackclub_refresh_token = new_token.refresh_token if new_token.refresh_token.present?

    self.hackclub_access_token = Current.hackclub_access_token if has_attribute?(:hackclub_access_token)
    if Current.hackclub_refresh_token.present? && has_attribute?(:hackclub_refresh_token)
      self.hackclub_refresh_token = Current.hackclub_refresh_token
    end
    save!(validate: false) if persisted? && changed?

    [ Current.hackclub_access_token, Current.hackclub_refresh_token ]
  end
end
