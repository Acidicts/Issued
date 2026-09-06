module DevlogHelper
  def markdown_to_html(text)
    return "" if text.blank?

    html = text.to_s
      .gsub(/^### (.+)$/, '<h3>\1</h3>')
      .gsub(/^## (.+)$/, '<h2>\1</h2>')
      .gsub(/^# (.+)$/, '<h1>\1</h1>')
      .gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
      .gsub(/\*(.+?)\*/, '<em>\1</em>')
      .gsub(/`(.+?)`/, '<code>\1</code>')
      .gsub(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
      .gsub(/^- (.+)$/, '<li>\1</li>')
      .gsub(/(<li>.*<\/li>\n?)+/) { |match| "<ul>#{match}</ul>" }
      .gsub(/\n\n/, '<br><br>')
      .gsub(/\n/, '<br>')

    html.html_safe
  end
end
