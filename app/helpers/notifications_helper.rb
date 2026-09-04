module NotificationsHelper
  # kind => [stamp mark, css modifier class]
  NOTIFICATION_STYLES = {
    approved: [ "✓", "approved" ],
    rejected: [ "✕", "rejected" ],
    review:   [ "…", "pending" ],
    shop:     [ "$", "shop" ],
    order:    [ "📦", "order" ],
    system:   [ "•", "system" ]
  }.freeze

  USER_TOKEN_PATTERN = /\{\{user:(\d+)\}\}/
  SHIP_TOKEN_PATTERN = /\{\{ship:(\d+)\}\}/
  SHIP_REQUEST_TOKEN_PATTERN = /\{\{ship_request:(\d+)\}\}/
  DEVLOG_TOKEN_PATTERN = /\{\{devlog:(\d+)\}\}/

  def notification_mark(kind)
    NOTIFICATION_STYLES.fetch(kind&.to_sym, [ "•", "system" ]).first
  end

  def notification_style_class(kind)
    NOTIFICATION_STYLES.fetch(kind&.to_sym, [ "•", "system" ]).last
  end

  # Renders a notification body, replacing {{user:ID}} tokens with a
  # name + admin-badge pill. Everything else is HTML-escaped first,
  # so user-controlled text (comments, names) can never inject markup.
  def render_notification_body(body)
    safe_body = ERB::Util.html_escape(body.to_s)

    safe_body
      .gsub(USER_TOKEN_PATTERN) do
        user = User.find_by(id: $1)
        user ? user_pill(user) : "unknown user"
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
      .html_safe
  end

  private

  def user_pill(user)
    content_tag(:a, class: "user-pill", href: user_path(user)) do
      concat content_tag(:span, user.name, class: "user-pill__name")
      concat content_tag(:span, admin_badge_svg(width: "1.55rem", height: "1.55rem", color: "#ec3750"), class: "user-pill__badge") if user.admin?
    end
  end

  def admin_user_pill(user)
    content_tag(:a, class: "user-pill", href: admin_user_path(user)) do
      concat content_tag(:span, user.name, class: "user-pill__name")
      concat content_tag(:span, admin_badge_svg(width: "1.55rem", height: "1.55rem", color: "#ec3750"), class: "user-pill__badge") if user.admin?
    end
  end

  def devlog_pill(devlog)
    content_tag(:span, class: "user-pill") do
      concat content_tag(:span, devlog.title, class: "user-pill__name")
    end
  end

  def ship_pill(ship)
    content_tag(:span, class: "user-pill") do
      concat content_tag(:span, ship.title, class: "user-pill__name")
    end
  end

  def ship_request_pill(ship_request)
    content_tag(:span, class: "user-pill") do
      concat content_tag(:span, ship_request.title, class: "user-pill__name")
    end
  end
end
