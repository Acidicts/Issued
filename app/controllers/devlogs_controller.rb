class DevlogsController < ApplicationController
  before_action :require_login
  before_action :set_devlog, only: [ :edit, :update ]
  before_action :require_owner_for_edit, only: [ :edit, :update ]
  before_action :require_owner_for_create, only: [ :create ]

  def edit
    render partial: "designs/devlogs/edit", formats: [ :html ]
  end

  def create
    permitted = devlog_params
    image_file = params[:devlog][:image]
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))

    @design = Design.find_by(id: params[:devlog][:design_id])
    if @design.nil?
      redirect_to root_path, alert: "That design doesn't exist."
      return
    end
    @design.sync_hackatime_projects
    @design.save!

    if params[:devlog][:time].to_i > @design.unlogged_time
      redirect_to design_path(@design), alert: "You don't have that much unlogged time."
      return
    elsif params[:devlog][:time].to_i < 15*60
      redirect_to design_path(@design), alert: "Log at least 15mins per devlog."
      return
    elsif params[:devlog][:image].nil?
      redirect_to design_path(@design), alert: "Include a image of the current design."
      return
    end
    @devlog = @design.devlogs.new(permitted)

    if @devlog.save
      if image_file.present?
        save_image(@design.images.new(devlog: @devlog), image_file, remove_background: should_remove_bg)
      end
      redirect_to design_path(@design), notice: "Devlog created successfully."
    else
      flash.now[:alert] = "Unable to save devlog."
      render "designs/show", status: :unprocessable_entity
    end
  end

  def update
    permitted = devlog_params
    image_file = params[:devlog][:image]
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))

    @devlog = Devlog.find(params[:id])
    @design = @devlog.design

    # design_id is a substitute for ownership: re-pointing the devlog at somebody
    # else's design after require_owner_for_edit has already run would move a log onto
    # a page it was never authorised for. The log stays on the design it was created on.
    permitted.delete(:design_id)

    # #create caps time at the design's unlogged budget; #update has to as well, or a
    # devlog can be edited up to an arbitrary value and that feeds approved_seconds.
    if permitted.key?(:time)
      time = permitted[:time].to_i
      if time > @design.unlogged_time
        redirect_to design_path(@design), alert: "You don't have that much unlogged time."
        return
      elsif time < 15 * 60
        redirect_to design_path(@design), alert: "Log at least 15mins per devlog."
        return
      end
    end

    if image_file.present?
      save_image(@devlog.image || @design.images.new(devlog: @devlog), image_file, remove_background: should_remove_bg)
    end

    if @devlog.update(permitted)
      redirect_to design_path(@design), notice: "Devlog updated successfully."
    else
      flash.now[:alert] = "Unable to update devlog."
      render partial: "designs/devlogs/devlog", status: :unprocessable_entity
    end
  end

  private

  def devlog_params
    params.require(:devlog).permit(:title, :body, :time, :design_id, :remove_background)
  end

  def set_devlog
    @devlog = Devlog.find(params[:id])
  end

  def require_owner_for_edit
    require_owner(@devlog.design)
  end

  def require_owner_for_create
    design = Design.find_by(id: params.dig(:devlog, :design_id))
    return if design.nil? # #create reports the missing/unknown design itself

    require_owner(design)
  end
end
