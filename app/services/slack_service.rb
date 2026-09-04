# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class SlackService
  def initialize(token: nil)
    @token = token || ENV["SLACK_BOT_TOKEN"]
  end

  # Fetches the raw Slack user object for a given Slack user ID, or nil.
  def user_info(id)
    return nil if id.blank? || @token.blank?

    uri = URI("https://slack.com/api/users.info")
    uri.query = URI.encode_www_form(user: id)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 5) { |http| http.request(req) }
    data = JSON.parse(res.body) rescue nil
    return nil unless data && data["ok"]

    data["user"]
  rescue => e
    Rails.logger.error("SlackService.user_info(#{id}) failed: #{e.message}")
    nil
  end

  # Returns the CDN profile image URL for a single Slack user ID, or nil.
  def profile_image(id)
    user = user_info(id)
    return nil unless user

    profile = user["profile"]
    return nil unless profile

    profile["image_192"] || profile["image_512"] || profile["image_72"]
  rescue => e
    Rails.logger.error("SlackService.profile_image(#{id}) failed: #{e.message}")
    nil
  end

  # Returns the slack display-name for a single Slack user ID, or nil.
  def display_name(id)
    user = user_info(id)
    return nil unless user

    profile = user["profile"]
    return nil unless profile

    profile["display_name"]
  rescue => e
    Rails.logger.error("SlackService.profile_image(#{id}) failed: #{e.message}")
    nil
  end
end
