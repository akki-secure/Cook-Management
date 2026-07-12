require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  def valid_params
    {
      recipe: {
        title: "新しいレシピ",
        description: "説明",
        instructions: "手順",
        cooking_time: 15,
        servings: 2,
        category_id: categories(:one).id,
        tag_names: "簡単, 新しい",
        ingredients_attributes: {
          "0" => { name: "にんじん", quantity: "1本" }
        }
      }
    }
  end

  test "index is accessible without login" do
    get recipes_url
    assert_response :success
  end

  test "index filters by keyword" do
    get recipes_url, params: { q: "肉じゃが" }
    assert_response :success
    assert_includes @response.body, recipes(:one).title
    assert_not_includes @response.body, recipes(:two).title
  end

  test "index filters by category" do
    get recipes_url, params: { category_id: categories(:two).id }
    assert_response :success
    assert_includes @response.body, recipes(:two).title
    assert_not_includes @response.body, recipes(:one).title
  end

  test "index filters by tag" do
    get recipes_url, params: { tag_id: tags(:two).id }
    assert_response :success
    assert_includes @response.body, recipes(:two).title
    assert_not_includes @response.body, recipes(:one).title
  end

  test "show is accessible without login" do
    get recipe_url(recipes(:one))
    assert_response :success
  end

  test "new redirects to login when not logged in" do
    get new_recipe_url
    assert_redirected_to login_url
  end

  test "new is accessible when logged in" do
    sign_in_as(users(:one))
    get new_recipe_url
    assert_response :success
  end

  test "create redirects to login when not logged in" do
    assert_no_difference "Recipe.count" do
      post recipes_url, params: valid_params
    end
    assert_redirected_to login_url
  end

  test "create saves a recipe with tags and ingredients when logged in" do
    sign_in_as(users(:one))

    assert_difference "Recipe.count", 1 do
      post recipes_url, params: valid_params
    end

    recipe = Recipe.order(:created_at).last
    assert_redirected_to recipe_url(recipe)
    assert_equal users(:one), recipe.user
    assert_equal [ "簡単", "新しい" ].to_set, recipe.tags.map(&:name).to_set
    assert_equal [ "にんじん" ], recipe.ingredients.map(&:name)
  end

  test "create renders new with unprocessable_entity when invalid" do
    sign_in_as(users(:one))

    assert_no_difference "Recipe.count" do
      post recipes_url, params: { recipe: valid_params[:recipe].merge(title: "") }
    end

    assert_response :unprocessable_entity
  end

  test "edit redirects when not the owner" do
    sign_in_as(users(:two))
    get edit_recipe_url(recipes(:one))
    assert_redirected_to recipes_url
  end

  test "edit is accessible for the owner" do
    sign_in_as(users(:one))
    get edit_recipe_url(recipes(:one))
    assert_response :success
  end

  test "update is rejected when not the owner" do
    sign_in_as(users(:two))
    patch recipe_url(recipes(:one)), params: { recipe: { title: "乗っ取り" } }
    assert_redirected_to recipes_url
    assert_not_equal "乗っ取り", recipes(:one).reload.title
  end

  test "update saves changes for the owner" do
    sign_in_as(users(:one))
    patch recipe_url(recipes(:one)), params: { recipe: { title: "更新後のタイトル" } }
    assert_redirected_to recipe_url(recipes(:one))
    assert_equal "更新後のタイトル", recipes(:one).reload.title
  end

  test "destroy is rejected when not the owner" do
    sign_in_as(users(:two))
    assert_no_difference "Recipe.count" do
      delete recipe_url(recipes(:one))
    end
    assert_redirected_to recipes_url
  end

  test "destroy removes the recipe for the owner" do
    sign_in_as(users(:one))
    assert_difference "Recipe.count", -1 do
      delete recipe_url(recipes(:one))
    end
    assert_redirected_to recipes_url
  end
end
