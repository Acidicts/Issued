class DevlogsController < ApplicationController
  before_action :require_login

  def edit
    @devlog = Devlog.find(params[:id])

    render partial: "designs/devlogs/edit", formats: [ :html ]
  end

  def create
    @design = Design.find(params[:devlog][:design_id])
    @design.sync_hackatime_projects
    if params[:devlog][:time].to_i > @design.unlogged_time
      redirect_to design_path(@design), alert: "You don't have that much unlogged time."
      return
    elsif params[:devlog][:time].to_i < 15*60
      redirect_to design_path(@design), alert: "Log at least 15mins per devlog."
      return
    end
    @devlog = @design.devlogs.new(devlog_params)

    if @devlog.save
      redirect_to design_path(@design), notice: "Devlog created successfully."
    else
      flash.now[:alert] = "Unable to save devlog."
      render "designs/show", status: :unprocessable_entity
    end
  end

  def update
    @devlog = Devlog.find(params[:id])
    @design = @devlog.design

    if @devlog.update(devlog_params)
      redirect_to design_path(@design), notice: "Devlog updated successfully."
    else
      flash.now[:alert] = "Unable to update devlog."
      render "designs/show", status: :unprocessable_entity
    end
  end

  private

  def devlog_params
    params.require(:devlog).permit(:title, :body, :time, :design_id)
  end
end
