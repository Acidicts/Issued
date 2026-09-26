class Reviewer::DashboardController < Reviewer::ReviewerController
  def index
    @ship_requests = ShipRequest.where(status: :pending).joins(design: :user).pluck("design.id", "design.name", "ship_requests.id", "users.name", "users.id")

    render "reviewer/dashboard/index"
  end
end
