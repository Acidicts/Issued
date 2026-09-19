module DevlogHelper
  def markdown_to_html(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      fenced_code_blocks: true,
      strikethrough: true,
      no_intra_emphasis: true,
      tables: true,
      footnotes: true
    )

    checkbox_lines = text.to_s.lines.map do |line|
      if line =~ /^\s*-?\s*\[x\]\s*(.*)/
        %(<div class="form-check cursor-pointer"><input type="checkbox" checked disabled><span class="form-check-label">#{$1.strip}</span></div>\n)
      elsif line =~ /^\s*-?\s*\[ \]\s*(.*)/
        %(<div class="form-check cursor-pointer"><input type="checkbox" disabled><span class="form-check-label">#{$1.strip}</span></div>\n)
      else
        line.lstrip
      end
    end.join

    html = markdown.render(checkbox_lines)

    Rails::Html::SafeListSanitizer.new.sanitize(html,
      tags: %w[h1 h2 h3 h4 h5 h6 strong em code a ul ol li br hr table thead tbody tr th td pre blockquote img input div span],
      attributes: %w[href src alt checked disabled type class]
    ).html_safe
  end
end
