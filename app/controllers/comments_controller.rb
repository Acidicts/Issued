class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_comment, only: [ :edit, :update ]
  before_action :require_owner_for_edit, only: [ :edit, :update ]

  def edit
    render partial: "designs/devlogs/edit", formats: [ :html ]
  end

  def update
  end

  def create
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

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def require_owner_for_edit
    unless @comment.user == current_user || current_user.admin?
      redirect_to root_path, alert: "You are not authorized to perform that action."
    end
  end
end
