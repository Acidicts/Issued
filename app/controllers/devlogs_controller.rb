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

    @design = Design.find(params[:devlog][:design_id])
    @design.sync_hackatime_projects
    @design.save!

    if params[:devlog][:time].to_i > @design.unlogged_time
      redirect_to design_path(@design), alert: "You don't have that much unlogged time."
      return
    elsif params[:devlog][:time].to_i < 15*60
      redirect_to design_path(@design), alert: "Log at least 15mins per devlog."
      return
    end
    @devlog = @design.devlogs.new(permitted)

    if @devlog.save
      if image_file.present?
        img = @design.images.create!(image_file: image_file, devlog: @devlog)
        RemoveBackgroundJob.perform_later(img.id) if should_remove_bg
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

    if image_file.present?
      image = @devlog.image || @design.images.new(devlog: @devlog)
      image.update!(image_file: image_file)
      RemoveBackgroundJob.perform_later(image.id) if should_remove_bg
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
    design = Design.find(params[:devlog][:design_id])
    require_owner(design)
  end
end
