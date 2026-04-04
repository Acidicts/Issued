class GenerateRsvpsOgImageJob < ApplicationJob
  queue_as :default

  def perform
    RsvpsOgImageCache.write!(count: Rsvp.count)
  end
end