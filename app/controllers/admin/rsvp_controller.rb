class Admin::RsvpController < Admin::DashboardController
  def index
    @rsvps = Rsvp.all
  end

  def delete
    Rsvp.find(params[:id]).destroy
    redirect_to admin_rsvp_path
  end
end
