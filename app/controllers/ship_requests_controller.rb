class ShipRequestsController < ApplicationController
  def new
    @design = Design.find(params[:design_id])
    @ship_request = @design.ship_requests.new()
  end

  def create
    permitted = ship_request_params
    image_file = permitted.delete(:image)
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))

    @design = Design.find(params[:ship_request][:design_id])

    if !@design.devlogs.any?
      redirect_to design_path(@design), alert: "You don't have any unshipped devlogs."
      return
    end
    @ship_request = @design.ship_requests.new(permitted)

    if @ship_request.save
      @design.devlogs.where(ship_request: nil).update_all(ship_request_id: @ship_request.id)

      if image_file.present?
        img = @design.images.create!(image_file: image_file, devlog: @ship_request)
        RemoveBackgroundJob.perform_later(img.id) if should_remove_bg
      end
      redirect_to design_path(@design), notice: "Ship request created successfully."
    else
      flash.now[:alert] = "Unable to save ship request."
      render "designs/show", status: :unprocessable_entity
    end
  end

  private

  def ship_request_params
    params.require(:ship_request).permit(:title, :body, :time, :design_id, :remove_background, :image)
  end
end
