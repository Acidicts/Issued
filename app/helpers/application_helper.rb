require "net/http"
require "cgi"

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

  USER_TOKEN_PATTERN = /\{\{user:(\d+)\}\}/ # User Profile
  REVIEWER_ENHANCED_USER_TOKEN_PATTERN = /\{\{reviewer_user:(\d+)\}\}/ # Enhanced User Profile
  REVIEWER_USER_TOKEN_PATTERN = /\{\{reviewer-user:(\d+)\}\}/ # Reviewer Profile
  ADMIN_USER_TOKEN_PATTERN = /\{\{admin-user:(\d+)\}\}/ # Admin Profile

  SHIP_TOKEN_PATTERN = /\{\{ship:(\d+)\}\}/
  SHIP_REQUEST_TOKEN_PATTERN = /\{\{ship_request:(\d+)\}\}/
  DEVLOG_TOKEN_PATTERN = /\{\{devlog:(\d+)\}\}/
  DESIGN_TOKEN_PATTERN = /\{\{design:(\d+)\}\}/
  SLACK_TOKEN_PATTERN = /\{\{slack:\s*([A-Z0-9]+)\s*\}\}/

  # render_encoded("{{slack:U078KKF3R1Q}}", context: :header)
  # {{slack:U078KKF3R1Q}}

  def render_encoded(body, context: :body, classes: "")
    safe_body = ERB::Util.html_escape(body.to_s)

    safe_body
      .gsub(USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? user_pill(user, context: context, classes: classes) : "unknown user"
      end
      .gsub(REVIEWER_ENHANCED_USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? reviewer_user_pill(user, context: context, classes: classes) : "unknown user"
      end
      .gsub(REVIEWER_USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? reviewer_profile_user_pill(user, context: context, classes: classes) : "unknown user"
      end
      .gsub(ADMIN_USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? admin_user_pill(user, context: context, classes: classes) : "unknown user"
      end
      .gsub(SHIP_TOKEN_PATTERN) do
        ship = Ship.find_by(id: $1)
        ship ? ship_pill(ship, context: context, classes: classes) : "unknown ship"
      end
      .gsub(SHIP_REQUEST_TOKEN_PATTERN) do
        ship_request = ShipRequest.find_by(id: $1)
        ship_request ? ship_request_pill(ship_request, context: context, classes: classes) : "unknown ship request"
      end
      .gsub(DEVLOG_TOKEN_PATTERN) do
        devlog = Devlog.find_by(id: $1)
        devlog ? devlog_pill(devlog, context: context, classes: classes) : "unknown devlog"
      end
      .gsub(DESIGN_TOKEN_PATTERN) do
        design = Design.find_by(id: $1)
        design ? design_pill(design, context: context, classes: classes) : "unknown design"
      end
      .gsub(SLACK_TOKEN_PATTERN) do
        slack_pill($1, context: context, classes: classes)
      end
      .html_safe
  end

  private

  def pill_context_class(context)
    context == :heading ? "pill--heading" : "pill--body"
  end

  def user_pill(user, context: :body, classes: "")
    content_tag(:a, class: "pill user-pill #{pill_context_class(context)} #{classes}".strip, href: user_path(user), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, user.name, class: "user-pill__name pill__name")
    end
  end

  def reviewer_profile_user_pill(user, context: :body, classes: "")
    content_tag(:a, class: "pill user-pill #{pill_context_class(context)} #{classes}".strip, href: reviewer_user_path(user), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, user.name, class: "user-pill__name pill__name")
    end
  end

  def reviewer_user_pill(user, context: :body, classes: "")
    content_tag(:a, class: "pill user-pill #{pill_context_class(context)} #{classes}".strip, href: reviewer_user_path(user), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, user.name, class: "user-pill__name pill__name")
    end
  end

  def slack_pill(slack_id, context: :body, classes: "")
    content_tag(:a, class: "pill slack-pill #{pill_context_class(context)} #{classes}".strip, href: "https://hackclub.slack.com/team/#{slack_id}") do
      concat content_tag(:span, slack_id, class: "slack-pill__name pill__name")
    end
  end

  def admin_user_pill(user, context: :body, classes: "")
    content_tag(:a, class: "pill admin-user-pill #{pill_context_class(context)} #{classes}".strip, href: admin_user_path(user), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, user.name, class: "user-pill__name pill__name")
      concat content_tag(:span, admin_badge_svg(width: "1.55rem", height: "1.55rem", color: "#ec3750"), class: "user-pill__badge") if user.admin?
    end
  end

  def design_pill(design, context: :body, classes: "")
    content_tag(:a, class: "pill design-pill #{pill_context_class(context)} #{classes}".strip, href: design_path(design), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, design.name, class: "design-pill__name pill__name")
    end
  end

  def devlog_pill(devlog, context: :body, classes: "")
    content_tag(:span, class: "pill devlog-pill #{pill_context_class(context)} #{classes}".strip) do
      concat content_tag(:span, devlog.title, class: "devlog-pill__name pill__name")
    end
  end

  def ship_pill(ship, context: :body, classes: "")
    content_tag(:span, class: "pill ship-pill #{pill_context_class(context)} #{classes}".strip) do
      concat content_tag(:span, ship.title, class: "ship-pill__name pill__name")
    end
  end

  def ship_request_pill(ship_request, context: :body, classes: "")
    content_tag(:a, class: "pill ship-request-pill #{pill_context_class(context)} #{classes}".strip, href: design_path(ship_request.design), data: { turbo_frame: "_top" }) do
      concat content_tag(:span, ship_request.title, class: "ship-request-pill__name pill__name")
    end
  end

  # Sign-in control, posted straight at the OAuth request phase.
  #
  # The request phase is POST-only and CSRF-checked, so a link to it cannot start a login:
  # GET would let another site start an OAuth flow in a victim's browser, and a GET carries no
  # token to satisfy the CSRF check. Pointing a link at /login only moves the problem, because
  # that page then has to render a form which POSTs onwards, which is the interstitial page
  # this replaces. Submitting from the page the user is already on keeps one click and no
  # intermediate page.
  #
  # Turbo is disabled on the form for the same reason the old handoff page dropped its layout:
  # Turbo fetch-follows the resulting redirect to auth.hackclub.com, that cross-origin response
  # carries no CORS headers, and the navigation becomes a content-type-mismatch error instead
  # of the Hack Club login.
  def oauth_login_form(origin: nil, label: "Login", **options)
    unless hackclub_oauth_configured?
      # Let /login render the "OAuth is not configured" alert.
      return link_to(label, login_path(redirect: origin), **options)
    end

    # per_form_csrf_tokens binds the token to the action string, so the origin has to be part
    # of the URL handed to button_to. Merging it in afterwards would mint the token for one
    # action and submit to another, and the request phase would reject it.
    action = hackclub_auth_path
    action += "?origin=#{CGI.escape(origin)}" if origin.present?

    button_to(label, action, form: { class: "oauth-handoff-form", data: { turbo: false } }, **options)
  end

  def hackclub_oauth_configured?
    ENV["HACKCLUB_CLIENT_ID"].present? && ENV["HACKCLUB_CLIENT_SECRET"].present?
  end
end
