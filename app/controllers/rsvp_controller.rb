class RsvpController < ApplicationController
  before_action :require_login, except: [ :index ]

  def index
    @running = ENV["RUNNING"] == "true"
    @ended = ENV["ENDED"] == "true"
    @already_rsvped = signed_in? && Rsvp.exists?(user: current_user)
    @can_rsvp = signed_in? && !@running && !@ended && !@already_rsvped

    render "rsvp/index"
  end

  def submit
    unless signed_in?
      redirect_to login_path(redirect: rsvp_path), alert: "Please sign in to RSVP."
      return
    end

    if ENV["RUNNING"] == "true" || ENV["ENDED"] == "true"
      redirect_to rsvp_path, alert: "RSVPs are closed right now."
      return
    end

    Rsvp.find_or_create_by!(user: current_user)

    redirect_to rsvp_thanks_path, notice: "You're on the list."
  end

  def thanks
    @open = ENV["RUNNING"] != "true" && ENV["ENDED"] != "true"
    render "rsvp/thanks"
  end

  def submit_after_login
    unless signed_in?
      redirect_to login_path(redirect: rsvp_submit_after_login_path), alert: "Please sign in to RSVP."
      return
    end

    if ENV["RUNNING"] == "true" || ENV["ENDED"] == "true"
      redirect_to rsvp_path, alert: "RSVPs are closed right now."
      return
    end

    Rsvp.find_or_create_by!(user: current_user)

    redirect_to rsvp_thanks_path, notice: "You're on the list."
  end
end
