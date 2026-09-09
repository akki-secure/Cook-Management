module ApplicationHelper
  # ヘッダーnavのラベル・並び順の唯一の定義元。実際のヘッダー(application.html.erb)と
  # 使い方ページ(static_pages/help.html.erb)の両方がここを参照することで、
  # 実装が2箇所に分かれて食い違うのを防ぐ。
  def logged_in_nav_items
    [
      { label: "新規レシピ", url: new_recipe_path },
      { label: "マイページ", url: profile_path },
      { label: "モンスター図鑑", url: monsters_path }
    ]
  end

  def logged_out_nav_items
    [
      { label: "ログイン", url: login_path },
      { label: "新規登録", url: signup_path }
    ]
  end
end
