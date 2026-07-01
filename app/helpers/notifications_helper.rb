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

  def notification_mark(kind)
    NOTIFICATION_STYLES.fetch(kind&.to_sym, ["•", "system"]).first
  end

  def notification_style_class(kind)
    NOTIFICATION_STYLES.fetch(kind&.to_sym, ["•", "system"]).last
  end
end
