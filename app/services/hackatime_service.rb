require "net/http"
require "json"
require "uri"

class HackatimeService
  BASE_URL = "https://hackatime.hackclub.com"
  API_PATH = "/api/v1"

  def self.api_key
    ENV["HACKATIME_API_KEY"].presence
  end

  def self.available?
    api_key.present?
  end

  def self.start_date
    ENV["HACKATIME_START_DATE"].presence || 30.days.ago.to_date.to_s
  end

  def self.cache_ttl_seconds
    ENV.fetch("HACKATIME_CACHE_TTL_SECONDS", 300).to_i
  end

  def self.bypass_cache?
    ENV["HACKATIME_BYPASS_CACHE"].present?
  end

  def initialize(slack_id: nil)
    @slack_id = slack_id
  end

  def get_trusted_status(slack_id: nil)
    uid = slack_id || @slack_id
    return nil unless uid.present? && self.class.available?

    data = self.class.fetch_trust_status(uid)
    return nil unless data.is_a?(Hash)

    {
      "trust_level" => data["trust_level"],
      "trust_value" => data["trust_value"]
    }
  end

  def get_all_projects
    return [] unless @slack_id.present? && self.class.available?

    all_stats = self.class.fetch_stats(@slack_id, start_date: self.class.start_date)
    recent_stats = self.class.fetch_stats(@slack_id, start_date: 30.days.ago.to_date.to_s)

    all_projects = all_stats&.fetch(:projects, {}) || {}
    recent_projects = recent_stats&.fetch(:projects, {}) || {}

    all_projects.map do |name, total_seconds|
      {
        "name" => name,
        "seconds" => total_seconds,
        "recent_seconds" => recent_projects[name] || 0
      }
    end.sort_by { |project| [-project["recent_seconds"].to_i, -project["seconds"].to_i, project["name"].to_s.downcase] }
  end

  def self.fetch_stats(hackatime_uid, start_date: nil, end_date: nil)
    return nil unless hackatime_uid.present? && available?

    params = { features: "projects" }
    params[:start_date] = start_date if start_date.present?
    params[:end_date] = end_date if end_date.present?

    cache_key = "hackatime:stats:#{hackatime_uid}:#{params[:start_date]}:#{params[:end_date] || 'none'}"
    unless bypass_cache?
      cached = Rails.cache.read(cache_key)
      return cached if cached
    end

    data = get_json("users/#{URI.encode_www_form_component(hackatime_uid)}/stats", params)
    return nil unless data.is_a?(Hash)

    project_list = Array(data.dig("data", "projects"))
    result = {
      projects: project_list.each_with_object({}) do |project, summary|
        summary[project["name"]] = project["total_seconds"].to_i
      end,
      banned: data.dig("trust_factor", "trust_value").to_i == 1
    }

    Rails.cache.write(cache_key, result, expires_in: cache_ttl_seconds.seconds) unless bypass_cache?
    result
  rescue => error
    Rails.logger.error("HackatimeService.fetch_stats error: #{error.class} #{error.message}")
    nil
  end

  def self.fetch_trust_status(slack_id)
    return nil unless slack_id.present? && available?

    get_json("users/#{URI.encode_www_form_component(slack_id)}/trust_factor")
  rescue => error
    Rails.logger.error("HackatimeService.fetch_trust_status error: #{error.class} #{error.message}")
    nil
  end

  def self.get_json(path, params = {})
    uri = URI.parse(BASE_URL)
    uri.path = API_PATH + "/" + path.to_s.sub(%r{^/+}, "")
    uri.query = URI.encode_www_form(params) if params.any?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{api_key}" if api_key
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 10) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => error
    Rails.logger.error("HackatimeService.get_json parse error: #{error.message}")
    nil
  end
end
