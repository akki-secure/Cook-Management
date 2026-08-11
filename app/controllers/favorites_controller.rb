class FavoritesController < ApplicationController
  before_action :require_login
  before_action :set_recipe

  def create
    current_user.favorites.find_or_create_by!(recipe: @recipe)
    AppEventLogger.log(event: "favorite.created", user: current_user, recipe_id: @recipe.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @recipe }
    end
  end

  def destroy
    current_user.favorites.find_by(recipe: @recipe)&.destroy
    AppEventLogger.log(event: "favorite.destroyed", user: current_user, recipe_id: @recipe.id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @recipe }
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end
end
