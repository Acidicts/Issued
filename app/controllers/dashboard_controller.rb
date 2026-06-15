class DashboardController < ApplicationController
  layout "application"
  before_action :set_nav
  before_action :require_login

  def index
    @user = current_user
    @orders = @user ? @user.orders : []
    @designs = current_user.designs
    @products = Rails.cache.fetch("products/all", expires_in: 5.minutes) { Product.all.to_a }

    # Hackatime integration
    if @user&.slack_id.present? && HackatimeService.available?
      cache_key = "hackatime/projects/#{@user.slack_id}"
      @hackatime_projects = Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
        HackatimeService.new(slack_id: @user.slack_id).get_all_projects
      end
    else
      @hackatime_projects = []
    end

    # Pipeline counts
    orders = @user.orders.includes(:design, :product)
    pipeline_key = "pipeline/#{@user.id}"
    @pipeline = Rails.cache.fetch(pipeline_key, expires_in: 1.minute) do
      [
        orders.where(status: :pending).count,
        orders.where(status: :processing).count,
        orders.where(status: :production).count,
        orders.where(status: :completed).count
      ]
    end
  end

  private

  def set_nav
    @nav = "dashboard"
  end
end
