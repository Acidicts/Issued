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
    unless commentable
      head :bad_request
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
    commentable = commentable_class.constantize.find(params[:commentable_id])
    render partial: "comments/comment_box", formats: [ :html ], locals: { commentable_class: commentable_class, commentable_id: params[:commentable_id], commentable: commentable }
  end

  private

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
