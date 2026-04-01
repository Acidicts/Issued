class DesignsController < ApplicationController
  layout "application"
  before_action :set_nav
  before_action :ensure_signed_in
  before_action :find_design, only: [:show, :edit, :update]

  def index
    @designs = current_user.designs.order(updated_at: :desc)
  end

  def show
  end

  def new
    @design = current_user.designs.new(name: "Untitled Design", description: "Draft description", time: 0)
    render :editor
  end

  def create
    @design = current_user.designs.new(design_params)
    @design.time ||= 0
    @design.description = "Draft description" if @design.description.blank?

    svg_code = params[:design_svg_code].presence || @design.svg_content
    @design.attach_svg_from_text(svg_code) if svg_code.present?

    if params[:elapsed_seconds].present?
      @design.time = (@design.time || 0) + params[:elapsed_seconds].to_i
    end

    if @design.save
      create_edit_session(@design, params[:elapsed_seconds])
      redirect_to edit_design_path(@design), notice: "Design saved successfully."
    else
      error_text = @design.errors.full_messages.to_sentence.presence || "Unknown reason"
      flash.now[:alert] = "Unable to save design: #{error_text}."
      render :editor, status: :unprocessable_entity
    end
  end

  def edit
    # reuse editor UI (pre-filled by @design)
    render :editor
  end

  def update
    @design.assign_attributes(design_params)

    if params[:design_svg_code].present?
      @design.attach_svg_from_text(params[:design_svg_code])
    end

    if params[:elapsed_seconds].present?
      elapsed = params[:elapsed_seconds].to_i
      @design.time = (@design.time || 0) + elapsed
    end

    if @design.save
      create_edit_session(@design, params[:elapsed_seconds])
      respond_to do |format|
        format.html { redirect_to edit_design_path(@design), notice: "Design updated successfully." }
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
    params.fetch(:design, {}).permit(:name, :description)
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
