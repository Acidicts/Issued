class DesignsController < ApplicationController
  layout "application"
  before_action :set_nav
  before_action :ensure_signed_in
  before_action :find_design, only: [ :show, :edit, :update ]
  before_action :load_hackatime_projects, only: [ :new, :edit, :create, :update, :editor ]

  def editor
    @design ||= current_user.designs.new(name: "Untitled Design", description: "Draft description", time: 0)
    render "designs/editor"
  end

  def index
    @designs = current_user.designs.order(updated_at: :desc)
  end

  def show
  end

  def new
    @design = current_user.designs.new(name: "Untitled Design", description: "Draft description", time: 0)
    render "designs/new"
  end

  def create
    @design = current_user.designs.new(design_params)
    @design.time ||= 0
    @design.description = "Draft description" if @design.description.blank?

    sync_hackatime_project
    @design.svg_code = params[:design_svg_code] if params.key?(:design_svg_code)

    if params[:elapsed_seconds].present?
      @design.time = (@design.time || 0) + params[:elapsed_seconds].to_i
    end

    if @design.save
      create_edit_session(@design, params[:elapsed_seconds])
      redirect_to editor_design_path(@design), notice: "Design saved successfully."
    else
      error_text = @design.errors.full_messages.to_sentence.presence || "Unknown reason"
      flash.now[:alert] = "Unable to save design: #{error_text}."
      render :editor, status: :unprocessable_entity
    end
  end

  def edit
    render "designs/edit"
  end

  def update
    @design.assign_attributes(design_params)
    sync_hackatime_project
    @design.svg_code = params[:design_svg_code] if params.key?(:design_svg_code)

    if params[:elapsed_seconds].present?
      elapsed = params[:elapsed_seconds].to_i
      @design.time = (@design.time || 0) + elapsed
    end

    if @design.save
      create_edit_session(@design, params[:elapsed_seconds])
      respond_to do |format|
        format.html do
          target = params["origin"] == "edit" ? design_path(@design) : edit_design_path(@design)
          redirect_to target, notice: "Design updated successfully."
        end
        format.json { render json: { success: true, time: @design.time } }
      end
    else
      flash.now[:alert] = "Unable to update design."
      render :editor, status: :unprocessable_entity
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
    params.fetch(:design, {}).permit(:name, :description, :hackatime_project, :image)
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

  def sync_hackatime_project
    return unless params[:design]&.key?(:hackatime_project)

    project_name = params[:design][:hackatime_project].presence
    if project_name.present? && current_user&.slack_id.present? && HackatimeService.available?
      project = @hackatime_projects.find { |p| p["name"] == project_name } || HackatimeService.new(slack_id: current_user.slack_id).get_all_projects.find { |p| p["name"] == project_name }
      @design.hackatime_project = project_name
      @design.hackatime_seconds = project ? project["seconds"].to_i : 0
    else
      @design.hackatime_project = nil
      @design.hackatime_seconds = nil
    end
  end

  def create_edit_session(design, elapsed_seconds)
    elapsed = elapsed_seconds.to_i
    return if elapsed <= 0

    DesignEditSession.create(
      design: design,
      user: current_user,
      started_at: Time.zone.now - elapsed,
      ended_at: Time.zone.now,
      duration_seconds: elapsed,
      activity_type: "edit"
    )
  end
end
