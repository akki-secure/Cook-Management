class RecipesController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy ]
  before_action :require_owner, only: [ :edit, :update, :destroy ]

  def index
    @recipes = Recipe.includes(:category, :tags, :user)
                      .search_by_keyword(params[:q])
                      .in_category(params[:category_id])
                      .tagged_with(params[:tag_id])
                      .order(created_at: :desc)
                      .distinct
    @categories = Category.order(:name)
    @tags = Tag.order(:name)
  end

  def show
  end

  def new
    @recipe = current_user.recipes.build
    @recipe.ingredients.build
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)
    assign_tags

    if @recipe.save
      redirect_to @recipe, notice: "レシピを作成しました。"
    else
      @recipe.ingredients.build if @recipe.ingredients.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @recipe.ingredients.build if @recipe.ingredients.empty?
  end

  def update
    assign_tags

    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: "レシピを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "レシピを削除しました。"
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def require_owner
    return if @recipe.user_id == current_user.id

    redirect_to recipes_path, alert: "この操作は許可されていません。"
  end

  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :instructions, :cooking_time, :servings,
      :category_id, :image,
      ingredients_attributes: [ :id, :name, :quantity, :_destroy ]
    )
  end

  def assign_tags
    names = params[:recipe][:tag_names].to_s.split(",").map(&:strip).reject(&:blank?).uniq
    @recipe.tags = names.map { |name| Tag.find_or_create_by(name: name) }
  end
end
