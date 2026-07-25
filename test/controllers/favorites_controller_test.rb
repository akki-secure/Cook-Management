require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to login when not logged in" do
    assert_no_difference "Favorite.count" do
      post recipe_favorite_url(recipes(:two))
    end
    assert_redirected_to login_url
  end

  test "create favorites a recipe when logged in" do
    sign_in_as(users(:one))

    assert_difference "Favorite.count", 1 do
      post recipe_favorite_url(recipes(:two))
    end
    assert_redirected_to recipes(:two)
  end

  test "create does not duplicate when already favorited" do
    sign_in_as(users(:two))

    assert_no_difference "Favorite.count" do
      post recipe_favorite_url(recipes(:one))
    end
  end

  test "destroy removes the favorite when logged in" do
    sign_in_as(users(:two))

    assert_difference "Favorite.count", -1 do
      delete recipe_favorite_url(recipes(:one))
    end
    assert_redirected_to recipes(:one)
  end

  test "destroy redirects to login when not logged in" do
    delete recipe_favorite_url(recipes(:one))
    assert_redirected_to login_url
  end
end
