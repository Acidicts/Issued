class DesignsController < ApplicationController
  layout "application"
  before_action :set_nav
  before_action :ensure_signed_in
  before_action :find_design, only: [ :show, :edit, :update, :image ]
  before_action :load_hackatime_projects, only: [ :new, :edit ]

  def index
    @designs = current_user.designs.order(updated_at: :desc)
  end

  def show
  end

  def image
    @image = @design.images.find(params[:image_id])
    render "designs/image"
  rescue
    render "designs/image"
  end

  def new
    @design = current_user.designs.new(name: "Untitled Design", description: "Draft description", time: 0)
    render "designs/new"
  end

  def create
    permitted = design_params
    image_file = permitted.delete(:image)
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))
    @design = current_user.designs.new(permitted)
    @design.time ||= 0
    @design.description = "Draft description" if @design.description.blank?

    sync_hackatime_project

    if @design.save
      if image_file.present?
        img = @design.images.create!(image_file: image_file)
        RemoveBackgroundJob.perform_later(img.id) if should_remove_bg
      end
      redirect_to design_path(@design), notice: "Design created successfully."
    else
      error_text = @design.errors.full_messages.to_sentence.presence || "Unknown reason"
      flash.now[:alert] = "Unable to save design: #{error_text}."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    render "designs/edit"
  end

  def update
    permitted = design_params
    image_file = permitted.delete(:image)
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))
    @design.assign_attributes(permitted)
    sync_hackatime_project

    if @design.save
      if image_file.present?
        img = @design.images.create!(image_file: image_file)
        RemoveBackgroundJob.perform_later(img.id) if should_remove_bg
      end
      redirect_to design_path(@design), notice: "Design updated successfully."
    else
      flash.now[:alert] = "Unable to update design."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_nav
    @nav = "dashboard"
  end

  def ensure_signed_in
    return if signed_in?

    redirect_to login_path(redirect: request.fullpath), alert: "Please sign in to access designs."
  end

  def find_design
    @design = current_user.designs.find(params[:id])
  end

  def design_params
    params.fetch(:design, {}).permit(:name, :description, :hackatime_project, :image, :remove_background)
  end

  def sync_hackatime_project
    return unless params[:design]&.key?(:hackatime_project)

    project_name = params[:design][:hackatime_project].presence
    if project_name.present? && current_user&.slack_id.present? && HackatimeService.available?
      projects = HackatimeService.new(slack_id: current_user.slack_id).get_all_projects
      project = projects.find { |p| p["name"] == project_name }
      @design.hackatime_project = project_name
      @design.hackatime_seconds = project ? project["seconds"].to_i : 0
    else
      @design.hackatime_project = nil
      @design.hackatime_seconds = nil
    end
  end

  def load_hackatime_projects
    if current_user&.slack_id.present? && HackatimeService.available?
      @hackatime_projects = HackatimeService.new(slack_id: current_user.slack_id).get_all_projects
    else
      @hackatime_projects = []
    end
  rescue StandardError => e
    Rails.logger.warn("Hackatime projects load failed: #{e.class} #{e.message}")
    @hackatime_projects = []
  end
end
