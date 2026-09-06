class ShipRequestController < ApplicationController
  def new
    @design = Design.find(params[:design_id])
    @ship_request = ShipRequest.new()
  end
end
