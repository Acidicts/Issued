module IconsHelper
  def admin_badge_svg(width: 0, height: 0, color: "#B7A878")
    content_tag(:svg,
      tag.path(d: "M16.437 11.023a1 1 0 0 1 .785.977v2.2H18a1 1 0 0 1 .907 1.42l-2.222 4.8a1 1 0 0 1-1.907-.42v-2.2H14a1 1 0 0 1-.908-1.42l2.223-4.8a1 1 0 0 1 1.122-.557z"),
      fill_rule: "evenodd", clip_rule: "evenodd", stroke_linejoin: "round",
      stroke_miterlimit: "1.414", xmlns: "http://www.w3.org/2000/svg",
      aria: { label: "admin-badge" }, viewBox: "0 0 32 32",
      preserveAspectRatio: "xMidYMid meet", fill: color, width: width, height: height, padding: 0
    ).html_safe
  end
end
