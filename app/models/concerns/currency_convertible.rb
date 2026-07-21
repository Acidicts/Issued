module CurrencyConvertible
  extend ActiveSupport::Concern

  def gbp_to_usd(gbp_amount)
    return if gbp_amount.blank?

    amount = BigDecimal(gbp_amount.to_s)
    rate = usd_per_gbp
    return if rate.nil?

    (amount * rate).round(2).to_f
  rescue ArgumentError, TypeError
    nil
  end

  def usd_to_gbp(usd_amount)
    return if usd_amount.blank?

    amount = BigDecimal(usd_amount.to_s)
    rate = usd_per_gbp
    return if rate.nil?

    (amount / rate).round(2).to_f
  rescue ArgumentError, TypeError
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
    require "net/http"

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
    Rails.logger.error("CurrencyConvertible.fetch_usd_conversion_rates error: #{error.class} #{error.message}")
    {}
  end
end
