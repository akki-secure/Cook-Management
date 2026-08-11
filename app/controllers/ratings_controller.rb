class RatingsController < ApplicationController
  before_action :require_login
  before_action :set_recipe

  def create
    @rating = current_user.ratings.find_or_initialize_by(recipe: @recipe)
    @rating.score = rating_params[:score]

    respond_to do |format|
      if @rating.save
        AppEventLogger.log(event: "rating.saved", user: current_user, recipe_id: @recipe.id, score: @rating.score)
        format.turbo_stream
        format.html { redirect_to @recipe, notice: "評価を登録しました。" }
      else
        format.html { redirect_to @recipe, alert: "評価に失敗しました。" }
      end
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def rating_params
    params.require(:rating).permit(:score)
  end
end
