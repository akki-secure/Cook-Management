require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects to login when not logged in" do
    assert_no_difference "Comment.count" do
      post recipe_comments_url(recipes(:two)), params: { comment: { body: "いいですね" } }
    end
    assert_redirected_to login_url
  end

  test "create saves a comment when logged in" do
    sign_in_as(users(:one))

    assert_difference "Comment.count", 1 do
      post recipe_comments_url(recipes(:two)), params: { comment: { body: "いいですね" } }
    end
    assert_redirected_to recipes(:two)
  end

  test "create fails with a blank body" do
    sign_in_as(users(:one))

    assert_no_difference "Comment.count" do
      post recipe_comments_url(recipes(:two)), params: { comment: { body: "" } }
    end
    assert_redirected_to recipes(:two)
  end

  test "edit redirects when not the owner" do
    sign_in_as(users(:one))
    get edit_comment_url(comments(:one))
    assert_redirected_to recipes(:one)
  end

  test "edit is accessible for the owner" do
    sign_in_as(users(:two))
    get edit_comment_url(comments(:one))
    assert_response :success
  end

  test "update is rejected when not the owner" do
    sign_in_as(users(:one))
    patch comment_url(comments(:one)), params: { comment: { body: "乗っ取り" } }
    assert_redirected_to recipes(:one)
    assert_not_equal "乗っ取り", comments(:one).reload.body
  end

  test "update saves changes for the owner" do
    sign_in_as(users(:two))
    patch comment_url(comments(:one)), params: { comment: { body: "更新後のコメント" } }
    assert_redirected_to recipes(:one)
    assert_equal "更新後のコメント", comments(:one).reload.body
  end

  test "destroy is rejected when not the owner" do
    sign_in_as(users(:one))
    assert_no_difference "Comment.count" do
      delete comment_url(comments(:one))
    end
    assert_redirected_to recipes(:one)
  end

  test "destroy removes the comment for the owner" do
    sign_in_as(users(:two))
    assert_difference "Comment.count", -1 do
      delete comment_url(comments(:one))
    end
    assert_redirected_to recipes(:one)
  end
end
