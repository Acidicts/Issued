class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :require_owner_for_edit, only: [ :edit, :update, :destroy ]

  def edit
    render partial: "designs/devlogs/edit", formats: [ :html ]
  end

  def update
  end

  def destroy
    return if @comment.admin_only
    @comment.destroy
    redirect_back fallback_location: root_path, notice: "Comment deleted."
  end

  def create
    commentable_class = params.dig(:comment, :commentable_type)
    unless COMMENTABLE_TYPES.include?(commentable_class)
      head :bad_request
      return
    end
    commentable = commentable_class.constantize.find_by(id: params.dig(:comment, :commentable_id))
    unless commentable && commentable_permitted?(commentable)
      head :forbidden
      return
    end
    @commentable = commentable
    @comment = current_user.comments.build(body: comment_params(params)[:body], commentable: commentable)

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path, notice: "Comment added." }
      end
    else
      redirect_back fallback_location: root_path, alert: "Could not save comment."
    end
  end

  COMMENTABLE_TYPES = %w[Design Devlog ShipRequest].freeze

  def comment_box
    commentable_class = params[:commentable_type]
    unless COMMENTABLE_TYPES.include?(commentable_class)
      head :bad_request
      return
    end
    commentable = commentable_class.constantize.find_by(id: params[:commentable_id])
    unless commentable && commentable_permitted?(commentable)
      head :forbidden
      return
    end
    render partial: "comments/comment_box", formats: [ :html ], locals: { commentable_class: commentable_class, commentable_id: params[:commentable_id], commentable: commentable }
  end

  private

  # Design and Devlog are shown on the public design showcase, so anyone signed in may
  # comment on them. A ShipRequest is only public once it has been reviewed or shipped
  # (ShipRequest#publicly_visible?), so before then it is the owner's alone — without
  # this check, guessable ids let anyone read and post in a pending request's thread.
  def commentable_permitted?(commentable)
    return true unless commentable.is_a?(ShipRequest)
    return true if current_user.admin? || current_user.reviewer?
    return true if commentable.publicly_visible?

    commentable.design&.user_id == current_user.id
  end

  def comment_params(params)
    params.fetch(:comment, {}).permit(:body)
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def require_owner_for_edit
    unless @comment.user == current_user || current_user.admin?
      redirect_to root_path, alert: "You are not authorized to perform that action."
    end
  end
end
