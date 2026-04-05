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
end
