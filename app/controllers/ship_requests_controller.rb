class ShipRequestsController < ApplicationController
  def next_step
    @design = Design.find(params[:design_id])

    if params[:step] == "start"
      render partial: "ship_requests/steps/checks"
    elsif params[:step] == "checks"
      @ship_request = @design.ship_requests.new()
      render partial: "ship_requests/steps/form"
    else
      render partial: "ship_requests/steps/overview"
    end
  end

  def resubmit
    @design = Design.find(params[:design_id])
    return unless current_user == @design.user

    if @design.ship_requests.where(status: :rejected).any?
      if @design.ship_requests.where(status: :rejected).last.update(status: :pending)
        redirect_to design_path(@design), info: "Successfully Re-Submitted"
      else
        redirect_to design_path(@design), info: "Failed to Re-Submit"
      end
    end
  end

  def create
    permitted = ship_request_params
    image_file = permitted.delete(:image)
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))

    @design = Design.find(params[:ship_request][:design_id])

    return unless current_user == @design.user

    if !@design.can_make_ship_request?
      redirect_to design_path(@design), alert: "You don't have all the requirements to ship"
      return
    end

    if !image_file.present?
      redirect_to design_path(@design), alert: "You are missing image file in your ship request"
      return
    end

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
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to design_path(@design), notice: "Ship request created successfully." }
      end
    else
      flash.now[:alert] = "Unable to save ship request."
      render "designs/show", status: :unprocessable_entity
    end
  end

  private

  def can_make_ship_request_checks(design)
    {
      "checks": {
        "valid_repo": valid_repo?(design),
        "valid_readme": valid_readme?(design),
        "image_exists": design.image?,
        "description": design.description,
        "ship_request_pending": design.ship_requests.where(status: :pending).any?
      }
    }
  end

  def ship_request_params
    params.require(:ship_request).permit(:title, :body, :time, :design_id, :remove_background, :image)
  end

  def valid_repo?(design)
    !design.repo.empty?
  end

  def valid_readme?(design)
    !design.readme.empty?
  end
end
