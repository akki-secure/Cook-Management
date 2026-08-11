class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_recipe, only: [ :create ]
  before_action :set_comment, only: [ :edit, :update, :destroy ]
  before_action :require_owner, only: [ :edit, :update, :destroy ]

  def create
    @comment = @recipe.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        AppEventLogger.log(event: "comment.created", user: current_user, recipe_id: @recipe.id, comment_id: @comment.id)
        format.turbo_stream
        format.html { redirect_to @recipe, notice: "コメントを投稿しました。" }
      else
        format.html { redirect_to @recipe, alert: "コメントを投稿できませんでした。" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("comment_form_errors",
            partial: "comments/errors", locals: { comment: @comment })
        end
      end
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      AppEventLogger.log(event: "comment.updated", user: current_user, comment_id: @comment.id)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @comment.recipe, notice: "コメントを更新しました。" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe = @comment.recipe
    comment_id = @comment.id
    @comment.destroy
    AppEventLogger.log(event: "comment.destroyed", user: current_user, comment_id: comment_id, recipe_id: @recipe.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @recipe, notice: "コメントを削除しました。" }
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def require_owner
    return if @comment.user_id == current_user.id

    redirect_to @comment.recipe, alert: "この操作は許可されていません。"
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
