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

    if RsvpsOgImageCache.stale?(max_age: 10.minutes)
      GenerateRsvpsOgImageJob.perform_later
      RsvpsOgImageCache.write!(count: @rsvp_count) unless RsvpsOgImageCache.exists?
    end

    @rsvps_og_image_path = RsvpsOgImageCache.public_url
  end

  private
  def set_nav
    @nav = "home"
  end
end
