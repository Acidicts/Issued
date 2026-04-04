class HomeController < ApplicationController
  before_action :set_nav

  def index
    @nav = nil
  end

  def about
  end

  def faq
  end

  def rsvps
    @rsvp_count = Rsvp.count
  end

  def rsvps_og_image
    rsvp_count = Rsvp.count

    svg = <<~SVG
      <svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Issued RSVP count">
        <defs>
          <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stop-color="#0f172a" />
            <stop offset="100%" stop-color="#1d4ed8" />
          </linearGradient>
        </defs>
        <rect width="1200" height="630" fill="url(#bg)" />
        <text x="72" y="152" fill="#93c5fd" font-size="44" font-family="Arial, Helvetica, sans-serif">Issued</text>
        <text x="72" y="300" fill="#ffffff" font-size="150" font-weight="700" font-family="Arial, Helvetica, sans-serif">#{ERB::Util.html_escape(rsvp_count)}</text>
        <text x="72" y="384" fill="#dbeafe" font-size="58" font-family="Arial, Helvetica, sans-serif">#{rsvp_count == 1 ? "Person RSVPed" : "People RSVPed"}</text>
        <text x="72" y="560" fill="#bfdbfe" font-size="36" font-family="Arial, Helvetica, sans-serif">issued.hackclub.com/rsvp</text>
      </svg>
    SVG

    response.headers["Cache-Control"] = "no-store"
    send_data svg, type: "image/svg+xml", disposition: "inline"
  end

  private
  def set_nav
    @nav = "home"
  end
end
