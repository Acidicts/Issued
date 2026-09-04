# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  credits                :integer
#  email                  :string
#  guide                  :boolean          default(FALSE), not null
#  hackclub_access_token  :text
#  hackclub_refresh_token :text
#  name                   :string
#  role                   :integer
#  threads                :integer
#  veri_level             :integer
#  ysws_eligible          :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  slack_id               :string
#
class User < ApplicationRecord
  has_many :designs, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :notifications, dependent: :destroy

  has_many :balance_events, dependent: :destroy

  validates :ysws_eligible, inclusion: { in: [ true, false ] }

  enum :role, { user: 0, admin: 1, superadmin: 2, reviewer: 3, system: 4 }, prefix: :role, default: :user
  attribute :veri_level, :integer
  attribute :email, :string
  attribute :threads, :integer, default: 0
  enum :veri_level, { unknown: 0, needs_submission: 1, pending: 2, verified: 3, ineligible: 4 }, prefix: :veri_level, default: :unknown

  attribute :credits, default: 0, nil: false
  attribute :guide, default: false, nil: false

  def verified_for_ysws?
    veri_level == "verified" && ysws_eligible
  end

  def admin?
    role == "admin" || role == "superadmin"
  end

  def reviewer?
    role == "reviewer"
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

  def calculate_threads
    calc_balance = balance_events.to_a.sum(&:amount)
    self.threads = calc_balance

    threads_changed?
  end

  def add_threads(name: nil, comment: nil, amount: 0, initiator: User.system_user)
    name ||= "#{amount.abs} threads added"
    comment ||= "Added by #{initiator.name}"

    transaction do
      balance_events.build(initiator: initiator, amount: amount.abs, comment: comment, name: name)

      if calculate_threads
        notifications.build(
          priority: :info,
          body: "#{user_token(initiator)} added #{amount.abs} threads to your balance"
        )
      end

      save!
    end
  end

  def remove_threads(name: nil, comment: nil, amount: 0, initiator: User.system_user)
    name ||= "#{amount.abs} threads removed"
    comment ||= "Removed by #{initiator.name}"

    transaction do
      balance_events.build(initiator: initiator, amount: (amount.abs * -1), comment: comment, name: name)

      if calculate_threads
        notifications.build(
          priority: :info,
          body: "#{user_token(initiator)} removed #{amount.abs} threads from your balance"
        )
      end

      save!
    end
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

  def self.system_user
    find_or_create_by!(name: "System", role: :system)
  end

  private

  def user_token(user)
    "{{user:#{user.id}}}"
  end
end
