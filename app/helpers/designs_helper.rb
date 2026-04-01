module DesignsHelper
  def svg_scaled(svg_markup)
    return "" unless svg_markup.present?

    fragment = Nokogiri::HTML::DocumentFragment.parse(svg_markup)
    svg = fragment.at_css("svg")
    return svg_markup.html_safe if svg.nil?

    # Ensure viewBox exists for pixel scaling
    unless svg["viewBox"].present?
      width = svg["width"].to_s.delete("px").to_f
      height = svg["height"].to_s.delete("px").to_f
      if width > 0 && height > 0
        svg["viewBox"] = "0 0 #{width} #{height}"
      end
    end

    svg["width"] = "100%"
    svg["height"] = "100%"
    svg["preserveAspectRatio"] = "xMidYMid meet"

    fragment.to_html.html_safe
  rescue StandardError
    svg_markup.html_safe
  end
end
