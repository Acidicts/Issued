require "net/http"

module ApplicationHelper
  include CurrencyConvertible

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

  def format_duration(total_seconds: 0, seconds_enabled: false)
    seconds = total_seconds.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60
    if seconds_enabled
      format("%02dhrs %02dmins %02ds", hours, minutes, remaining_seconds)
    else
      format("%02dhrs %02dmins", hours, minutes)
    end
  end

  USER_TOKEN_PATTERN = /\{\{user:(\d+)\}\}/
  ADMIN_USER_TOKEN_PATTERN = /\{\{admin-user:(\d+)\}\}/
  SHIP_TOKEN_PATTERN = /\{\{ship:(\d+)\}\}/
  SHIP_REQUEST_TOKEN_PATTERN = /\{\{ship_request:(\d+)\}\}/
  DEVLOG_TOKEN_PATTERN = /\{\{devlog:(\d+)\}\}/
  DESIGN_TOKEN_PATTERN = /\{\{design:(\d+)\}\}/

  def render_encoded(body)
    safe_body = ERB::Util.html_escape(body.to_s)

    safe_body
      .gsub(USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? user_pill(user) : "unknown user"
      end
      .gsub(ADMIN_USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? admin_user_pill(user) : "unknown user"
      end
      .gsub(SHIP_TOKEN_PATTERN) do
        ship = Ship.find_by(id: $1)
        ship ? ship_pill(ship) : "unknown ship"
      end
      .gsub(SHIP_REQUEST_TOKEN_PATTERN) do
        ship_request = ShipRequest.find_by(id: $1)
        ship_request ? ship_request_pill(ship_request) : "unknown ship request"
      end
      .gsub(DEVLOG_TOKEN_PATTERN) do
        devlog = Devlog.find_by(id: $1)
        devlog ? devlog_pill(devlog) : "unknown devlog"
      end
      .gsub(DESIGN_TOKEN_PATTERN) do
        design = Design.find_by(id: $1)
        design ? design_pill(design) : "unknown design"
      end
      .html_safe
  end

  private

  def user_pill(user)
    content_tag(:a, class: "pill user-pill", href: user_path(user)) do
      concat content_tag(:span, user.name, class: "user-pill__name")
    end
  end

  def admin_user_pill(user)
    content_tag(:a, class: "pill user-pill", href: admin_user_path(user)) do
      concat content_tag(:span, user.name, class: "user-pill__name pill__name")
      concat content_tag(:span, admin_badge_svg(width: "1.55rem", height: "1.55rem", color: "#ec3750"), class: "user-pill__badge") if user.admin?
    end
  end

  def design_pill(design)
    content_tag(:a, class: "pill design-pill", href: design_path(design)) do
      concat content_tag(:span, design.name, class: "design-pill__name pill__name")
    end
  end

  def devlog_pill(devlog)
    content_tag(:span, class: "pill user-pill") do
      concat content_tag(:span, devlog.title, class: "devlog-pill__name pill__name")
    end
  end

  def ship_pill(ship)
    content_tag(:span, class: "pill user-pill") do
      concat content_tag(:span, ship.title, class: "ship-pill__name pill__name")
    end
  end

  def ship_request_pill(ship_request)
    content_tag(:span, class: "pill user-pill") do
      concat content_tag(:span, ship_request.title, class: "ship-request-pill__name pill__name")
    end
  end
end
