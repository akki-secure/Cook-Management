class StaticPagesController < ApplicationController
  # 使い方ページの説明文。項目のラベル・並び順そのものは ApplicationHelper#logged_in_nav_items /
  # #logged_out_nav_items(実際のヘッダーnavと共通)を使い、ここでは説明文だけを対応させる。
  LOGGED_IN_ITEM_DESCRIPTIONS = {
    "新規レシピ" => { title: "レシピを追加する", desc: "新しい料理のレシピを登録できます。" },
    "マイページ" => { title: "自分の状況をまとめて見る", desc: "レベル・コイン・連続記録日数や、自分が投稿したレシピなどを確認できます。" },
    "モンスター図鑑" => { title: "モンスターをじっくり見る", desc: "ガチャで手に入れたモンスターを、イラスト付きの専用ページで一覧・詳細表示できます。まだ持っていないモンスターはシルエットで表示されます。" }
  }.freeze

  LOGGED_OUT_ITEM_DESCRIPTIONS = {
    "ログイン" => { title: "すでに登録した人はこちら", desc: "アカウントをお持ちの方は、ここからログインします。" },
    "新規登録" => { title: "はじめての方はこちら", desc: "まだアカウントがない方は、ここから新規登録できます。" }
  }.freeze

  def help
    @logged_in_items = with_badges_and_descriptions(helpers.logged_in_nav_items, LOGGED_IN_ITEM_DESCRIPTIONS, start: 2)
    @logged_out_items = with_badges_and_descriptions(helpers.logged_out_nav_items, LOGGED_OUT_ITEM_DESCRIPTIONS, start: 1)
  end

  private

  def with_badges_and_descriptions(items, descriptions, start:)
    items.each_with_index.map do |item, index|
      item.merge(badge: start + index, **descriptions.fetch(item[:label]))
    end
  end
end
