module ApplicationHelper
  # ヘッダーnavのラベル・並び順の唯一の定義元。実際のヘッダー(application.html.erb)と
  # 使い方ページ(static_pages/help.html.erb)の両方がここを参照することで、
  # 実装が2箇所に分かれて食い違うのを防ぐ。
  def logged_in_nav_items
    [
      { label: "新規レシピ", url: new_recipe_path },
      { label: "マイページ", url: profile_path },
      { label: "ガチャ", url: gacha_path },
      { label: "対戦", url: battle_path },
      { label: "モンスター図鑑", url: monsters_path }
    ]
  end

  def logged_out_nav_items
    [
      { label: "ログイン", url: login_path },
      { label: "新規登録", url: signup_path }
    ]
  end

  # ヘッダーとマイページの両方から呼ばれる、ユーザーアイコン表示の唯一の定義元。
  # 画像未添付の場合はユーザー名の頭文字を使った円形プレースホルダーを表示する。
  def avatar_tag(user, size:)
    if user.avatar_image.attached?
      image_tag user.avatar_image, alt: "", class: "avatar-icon avatar-icon--#{size}"
    else
      content_tag :div, user.name.first, class: "avatar-placeholder avatar-placeholder--#{size}"
    end
  end
end
