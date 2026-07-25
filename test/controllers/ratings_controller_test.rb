require "test_helper"

class RatingsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to login when not logged in" do
    assert_no_difference "Rating.count" do
      post ratings_url, params: { recipe_id: recipes(:two).id, rating: { score: 4 } }
    end
    assert_redirected_to login_url
  end

  test "create creates a new rating when logged in and none exists" do
    sign_in_as(users(:one))

    assert_difference "Rating.count", 1 do
      post ratings_url, params: { recipe_id: recipes(:two).id, rating: { score: 4 } }
    end
    assert_redirected_to recipes(:two)
    assert_equal 4, recipes(:two).ratings.find_by(user: users(:one)).score
  end

  test "create updates the existing rating instead of creating a duplicate" do
    sign_in_as(users(:two))

    assert_no_difference "Rating.count" do
      post ratings_url, params: { recipe_id: recipes(:one).id, rating: { score: 2 } }
    end
    assert_equal 2, ratings(:one).reload.score
  end

  test "create rejects an invalid score" do
    sign_in_as(users(:one))

    assert_no_difference "Rating.count" do
      post ratings_url, params: { recipe_id: recipes(:two).id, rating: { score: 6 } }
    end
    assert_redirected_to recipes(:two)
  end
end
