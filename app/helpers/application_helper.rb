require "net/http"

module ApplicationHelper
  def resolved_og_image_url(image_value)
    image = image_value.to_s.strip
    return if image.blank?

    return image if image.start_with?("http://", "https://")

    path = image.start_with?("/") ? image : asset_path(image)
    "#{app_base_url}#{path}"

  rescue StandardError
    nil
  end

  def app_base_url
    configured_base = ENV["APP_URL"].to_s.strip
    return configured_base.chomp("/") if configured_base.present?

    request.base_url
  end

  def gbp_to_usd(gbp_amount)
    return if gbp_amount.blank?

    amount = BigDecimal(gbp_amount.to_s)
    rate = usd_per_gbp
    return if rate.nil?

    (amount / rate).round(2)
  rescue ArgumentError, TypeError
    nil
  end

  def og_image_mime_type(image_url)
    return if image_url.blank?

    path = URI.parse(image_url).path
    case File.extname(path).downcase
    when ".png"
      "image/png"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".webp"
      "image/webp"
    when ".gif"
      "image/gif"
    when ".svg"
      "image/svg+xml"
    end
  rescue URI::InvalidURIError
    nil
  end

  def usd_per_gbp
    conversion_rates = Rails.cache.fetch("exchange_rate_api/latest_usd_conversion_rates", expires_in: 12.hours) do
      fetch_usd_conversion_rates
    end
    gbp_rate = conversion_rates.fetch("GBP", nil)
    return if gbp_rate.nil? || gbp_rate.to_d.zero?

    (1.to_d / gbp_rate.to_d).round(6)
  end

  def fetch_usd_conversion_rates
    api_key = ENV["EXCHANGE_RATE_API_KEY"].to_s.strip
    return {} if api_key.blank?

    uri = URI.parse("https://v6.exchangerate-api.com/v6/#{api_key}/latest/USD")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 10) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)
    return {} unless result["result"] == "success"

    result["conversion_rates"] || {}
  rescue => error
    Rails.logger.error("ApplicationHelper.fetch_usd_conversion_rates error: #{error.class} #{error.message}")
    {}
  end
end
