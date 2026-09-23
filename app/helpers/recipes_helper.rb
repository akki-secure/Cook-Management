module RecipesHelper
  # X(旧Twitter)のWeb Intentリンク。OAuth連携やAPIキーは不要で、
  # このURLを開くだけで本文入りのツイート作成画面が表示される。
  def twitter_share_url(recipe)
    params = {
      text: recipe.title,
      url: recipe_url(recipe),
      hashtags: "料理"
    }
    "https://twitter.com/intent/tweet?#{params.to_query}"
  end
end
