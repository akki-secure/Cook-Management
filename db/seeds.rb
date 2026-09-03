%w[和食 洋食 中華 イタリアン デザート スープ サラダ その他].each do |name|
  Category.find_or_create_by!(name: name)
end

[
  { name: "見習い料理人",   min_level: 1,  rank: 1 },
  { name: "一人前料理人",   min_level: 10, rank: 2 },
  { name: "料理上手",       min_level: 25, rank: 3 },
  { name: "熟練料理人",     min_level: 40, rank: 4 },
  { name: "料理マスター",   min_level: 60, rank: 5 },
  { name: "伝説の料理人",   min_level: 75, rank: 6 },
  { name: "料理の賢者",     min_level: 90, rank: 7 },
  { name: "料理の神",       min_level: 100, rank: 8 }
].each do |attrs|
  Title.find_or_create_by!(min_level: attrs[:min_level]) { |t| t.name = attrs[:name]; t.rank = attrs[:rank] }
end

# 初期実装時のプレースホルダー(色・形の自動描画)は、実際のイラスト素材に
# 差し替えたため削除する。sprite_keyが"color:"で始まるものが旧プレースホルダー。
Monster.where("sprite_key LIKE 'color:%'").destroy_all

[
  { name: "タマゴットン",     sprite_key: "egg_character.png",       description: "くりくりした目玉焼きのモンスター。" },
  { name: "ミルクドロップ",   sprite_key: "milk.png",                description: "こぼれたミルクのしずくから生まれたモンスター。" },
  { name: "パンケーキタワー", sprite_key: "pancake.png",             description: "ふわふわパンケーキを積み重ねたモンスター。" },
  { name: "カプチーノン",     sprite_key: "coffee_character.png",    description: "湯気が立つコーヒーカップのモンスター。" },
  { name: "アイスゴースト",   sprite_key: "ice.png",                 description: "ひんやりしたアイスクリームのお化けモンスター。" },
  { name: "スパゲッティーニ", sprite_key: "spaghetti_character.png", description: "ミートボール付きスパゲッティのモンスター。" },
  { name: "バーガーマン",     sprite_key: "hamburger_character.png", description: "ボリューム満点ハンバーガーのモンスター。" },
  { name: "ラザニアン",       sprite_key: "lasagna_character.png",   description: "何層にも重なったラザニアのモンスター。" },
  { name: "コーヒーゼリオ",   sprite_key: "cofeezeri.png",           description: "コーヒーゼリーにチェリーをのせたモンスター。" }
].each do |attrs|
  Monster.find_or_create_by!(name: attrs[:name]) do |m|
    m.sprite_key = attrs[:sprite_key]
    m.description = attrs[:description]
  end
end

# README記載のデモアカウント。新規登録なしですぐ動作確認できるようにするための固定データ。
[
  { name: "ウァッキー", email: "genki@example.com", password: "yoishou86!" },
  { name: "デモ太郎",   email: "demo1@example.com", password: "demoPass123!" },
  { name: "デモ花子",   email: "demo2@example.com", password: "demoPass456!" }
].each do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.name = attrs[:name]
    u.password = attrs[:password]
    u.password_confirmation = attrs[:password]
  end
end

# 図鑑・マイページの見た目をすぐ確認できるよう、代表アカウントに何体か持たせておく
demo_user = User.find_by(email: "genki@example.com")
if demo_user
  Monster.order(:id).limit((Monster.count / 2.0).ceil).each do |monster|
    UserMonster.find_or_create_by!(user: demo_user, monster: monster) { |um| um.acquired_on = Date.current }
  end
end
