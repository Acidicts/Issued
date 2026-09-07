class DesignsController < ApplicationController
  layout "application"
  before_action :require_login, except: [ :show, :image ]
  before_action :find_design, only: [ :show, :edit, :update, :image, :remove_hackatime_project, :add_hackatime_project_patch ]
  before_action :load_hackatime_projects, only: [ :new, :edit, :add_hackatime_project ]

  def index
    @designs = current_user.designs.order(updated_at: :desc)
  end

  def show
    @design =  Design.find(params[:id])
    @design.sync_hackatime_projects
    @design.update_logged_time
  end

  def image
    @image = @design.images.find(params[:image_id])
    render "designs/image"
  rescue
    render "designs/image"
  end

  def new
    if @current_user.guide == false
      @current_user.update!(guide: true)
    end
    @design = current_user.designs.new()
    render "designs/new"
  end

  def create
    permitted = design_params
    image_file = permitted.delete(:image)
    should_remove_bg = ActiveModel::Type::Boolean.new.cast(permitted.delete(:remove_background))
    @design = current_user.designs.new(permitted)
    @design.time ||= 0
    @design.description = "Draft description" if @design.description.blank?

    @design.sync_hackatime_projects

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
    @design.sync_hackatime_projects

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

  def remove_hackatime_project
    hp = @design.hackatime_projects.find(params[:hackatime_project_id])
    if @design.user_id != current_user.id
      redirect_to designs_path, alert: "You are not authorized to modify this design."
    elsif @design.ship_requests.where("created_at > ?", hp.created_at).exists?
      redirect_to edit_design_path(@design), alert: "Cannot remove this project — a ship request was created after it was added."
    else
      hp.destroy
      redirect_to edit_design_path(@design), notice: "Hackatime project removed."
    end
  end

  def add_hackatime_project
    @design = Design.find(params[:id])
    render "designs/hackatime/_add"
  end

  def add_hackatime_project_patch
    return unless @design
    return unless @design.user == current_user
    project_name = params[:design][:hackatime_project]
    if project_name.present?
      @design.hackatime_projects.find_or_create_by!(name: project_name)
    end
    @design.sync_hackatime_projects
    @design.save!
    redirect_to design_path(@design), notice: "Hackatime project added."
  end

  private

  def set_nav
    @nav = "designs"
  end

  def ensure_signed_in
    return if signed_in?

    redirect_to login_path(redirect: request.fullpath), alert: "Please sign in to access designs."
  end

  def find_design
    @design = Design.find(params[:id])
  end

  def design_params
    params.fetch(:design, {}).permit(:name, :description, :image, :remove_background)
  end

  def sync_hackatime_project
    return unless params[:design]&.key?(:hackatime_project)

    project_name = params[:design][:hackatime_project].presence
    return unless project_name.present? && current_user&.slack_id.present? && HackatimeService.available?

    already_linked = @design.hackatime_projects.exists?(name: project_name)
    return if already_linked

    projects = HackatimeService.new(slack_id: current_user.slack_id).get_all_projects
    project = projects.find { |p| p["name"] == project_name }
    return unless project.present?

    @design.hackatime_projects.new(name: project_name, time: project["seconds"])
    @design.hackatime_seconds = @design.hackatime_projects.sum(:time)
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
