class DashboardController < ApplicationController
  before_action :require_login

  STATUS_MAP = {
    approved: :approved,
    pending: :pending,
    submitted: :pending,
    unshipped: :draft,
    rejected: :rejected
  }.freeze

  SWATCHES = %w[#1F6F78 #B97F19 #847A63 #9B2E22 #3D7A4D #D6402C #2563EB #7C3AED #047857 #B45309].freeze

  def index
    @nav = "dashboard"
    @user = current_user
    @orders = @user ? @user.orders : []
    @products = Rails.cache.fetch("products/all", expires_in: 5.minutes) { Product.all.to_a }

    designs = current_user.designs
    notifications = current_user.notifications.limit(30)

    @maker = {
      id: @user.id.to_s.rjust(4, "0"),
      name: @user.name
    }

    @designs = designs.each_with_index.map do |d, i|
      view_status = STATUS_MAP[d.status.to_sym] || :draft
      {
        name: d.name,
        language: "SVG",
        category: "",
        status: view_status,
        swatch: SWATCHES[i % SWATCHES.size],
        note: ""
      }
    end

    @notifications = notifications.each_with_index.map do |d, i|
      {
        body: d.body,
        priority: d.priority,
        time: d.time,
        read: d.read,
        id: d.id
      }
    end

    @stats = {
      approved: designs.count(&:approved?),
      pending: designs.select { |d| d.pending? || d.submitted? }.count,
      draft: designs.count(&:unshipped?),
      rejected: designs.count(&:rejected?)
    }

    @threads = @user.threads || 0

    @shop_items = @products.map do |p|
      { name: p.type, cost: p.cost.to_i }
    end
  end
end
