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
  { name: "タマゴットン",     sprite_key: "egg_character.png",       description: "くりくりした目玉焼きのモンスター。",                 hp: 90,  attack: 16, defense: 8,  weakness: "shockwave", attacks: '["charge","shockwave","beam"]' },
  { name: "ミルクドロップ",   sprite_key: "milk.png",                description: "こぼれたミルクのしずくから生まれたモンスター。",       hp: 85,  attack: 15, defense: 7,  weakness: "lightning", attacks: '["charge","ice","lightning"]' },
  { name: "パンケーキタワー", sprite_key: "pancake.png",             description: "ふわふわパンケーキを積み重ねたモンスター。",           hp: 100, attack: 18, defense: 10, weakness: "fire",      attacks: '["charge","fire","shockwave"]' },
  { name: "カプチーノン",     sprite_key: "coffee_character.png",    description: "湯気が立つコーヒーカップのモンスター。",               hp: 88,  attack: 17, defense: 9,  weakness: "lightning", attacks: '["charge","lightning","wind"]' },
  { name: "アイスゴースト",   sprite_key: "ice.png",                 description: "ひんやりしたアイスクリームのお化けモンスター。",       hp: 82,  attack: 20, defense: 6,  weakness: "fire",      attacks: '["charge","ice","wind"]' },
  { name: "スパゲッティーニ", sprite_key: "spaghetti_character.png", description: "ミートボール付きスパゲッティのモンスター。",           hp: 95,  attack: 19, defense: 11, weakness: "shockwave", attacks: '["charge","shockwave","wind"]' },
  { name: "バーガーマン",     sprite_key: "hamburger_character.png", description: "ボリューム満点ハンバーガーのモンスター。",             hp: 110, attack: 22, defense: 16, weakness: "ice",       attacks: '["charge","fire","shockwave"]' },
  { name: "ラザニアン",       sprite_key: "lasagna_character.png",   description: "何層にも重なったラザニアのモンスター。",               hp: 130, attack: 23, defense: 18, weakness: "ice",       attacks: '["charge","fire","beam"]' },
  { name: "コーヒーゼリオ",   sprite_key: "cofeezeri.png",           description: "コーヒーゼリーにチェリーをのせたモンスター。",         hp: 90,  attack: 18, defense: 8,  weakness: "fire",      attacks: '["charge","ice","beam"]' },
  { name: "チャーハニオン",   sprite_key: "fried_rice_character.png", description: "パラパラに炒められたチャーハンのモンスター。",       hp: 105, attack: 21, defense: 15, weakness: "ice",       attacks: '["charge","fire","lightning"]' },
  { name: "オニオニキュー",   sprite_key: "onion_character.png",     description: "涙もろい玉ねぎのモンスター。",                       hp: 88,  attack: 17, defense: 9,  weakness: "wind",      attacks: '["charge","wind","lightning"]' },
  { name: "カキゴリラ",       sprite_key: "kakigori_character.png",  description: "夏の思い出が詰まったかき氷のモンスター。",             hp: 80,  attack: 15, defense: 6,  weakness: "fire",      attacks: '["charge","ice","wind"]' },
  { name: "カナッペット",     sprite_key: "canape.png",              description: "一口サイズでおしゃれなカナッペのモンスター。",         hp: 84,  attack: 19, defense: 10, weakness: "beam",      attacks: '["charge","beam","lightning"]' },
  { name: "ドラゴンゼリー",   sprite_key: "dragon_jelly.png",        description: "つやつや揺れるドラゴンの形をしたゼリーのモンスター。", hp: 92,  attack: 20, defense: 11, weakness: "fire",      attacks: '["charge","ice","shockwave"]' },
  { name: "チリエビーノ",     sprite_key: "ebi_chili.png",           description: "ピリ辛ソースをまとったエビチリのモンスター。",         hp: 110, attack: 25, defense: 17, weakness: "ice",       attacks: '["charge","fire","beam"]' },
  { name: "ピザーマン",       sprite_key: "pizza_man.png",           description: "焼きたてチーズがとろけるピザのモンスター。",           hp: 115, attack: 22, defense: 16, weakness: "ice",       attacks: '["charge","fire","wind"]' },
  { name: "クシダンゴン",     sprite_key: "shish_kebab.png",         description: "色とりどりの具が刺さった串焼きのモンスター。",         hp: 98,  attack: 21, defense: 13, weakness: "ice",       attacks: '["charge","shockwave","fire"]' },
  { name: "ヒエヒエソーメン", sprite_key: "somen.png",               description: "冷たいつゆで涼をとるそうめんのモンスター。",           hp: 86,  attack: 16, defense: 7,  weakness: "shockwave", attacks: '["charge","shockwave","ice"]' },
  { name: "メロンゼリオ",     sprite_key: "green_jelly.png",         description: "つやつや揺れるメロン味のゼリーのモンスター。",         hp: 85,  attack: 17, defense: 9,  weakness: "fire",      attacks: '["charge","beam","wind"]' },
  { name: "ソーダゼリオ",     sprite_key: "blue_jelly.png",          description: "しゅわしゅわ弾けるソーダ味のゼリーのモンスター。",     hp: 83,  attack: 16, defense: 8,  weakness: "lightning", attacks: '["charge","ice","beam"]' },
  { name: "ショートケーキング", sprite_key: "sponge_cake.png",       description: "いちごをのせた王様級のショートケーキのモンスター。",   hp: 100, attack: 19, defense: 12, weakness: "fire",      attacks: '["charge","fire","beam"]' },
  { name: "カレードン",       sprite_key: "monster_curry.png",        description: "こくのあるカレーソースに半分埋まったモンスター。",       hp: 105, attack: 24, defense: 13, weakness: "ice",       attacks: '["charge","fire","shockwave"]' },
  { name: "ギュウどん",       sprite_key: "monster_gyudon.png",       description: "甘辛いタレをまとった牛丼のモンスター。",               hp: 108, attack: 20, defense: 14, weakness: "wind",      attacks: '["charge","fire","lightning"]' },
  { name: "ハンバーグセッター", sprite_key: "monster_hamburg_set.png", description: "ジューシーなハンバーグと飲み物がセットになったモンスター。", hp: 112, attack: 22, defense: 15, weakness: "ice",       attacks: '["charge","fire","beam"]' },
  { name: "ホタテーン",       sprite_key: "monster_hotate.png",       description: "旨みたっぷりのホタテから生まれたモンスター。",           hp: 90,  attack: 17, defense: 10, weakness: "lightning", attacks: '["charge","ice","beam"]' },
  { name: "イカゾーン",       sprite_key: "monster_ikayaki.png",      description: "串に刺さったままワープするイカ焼きのモンスター。",       hp: 88,  attack: 19, defense: 9,  weakness: "fire",      attacks: '["charge","shockwave","wind"]' },
  { name: "オムラコン",       sprite_key: "monster_omurice.png",      description: "ふわふわ卵がとろけるオムライスのモンスター。",           hp: 95,  attack: 21, defense: 12, weakness: "shockwave", attacks: '["charge","fire","beam"]' },
  { name: "ピッザーン",       sprite_key: "monster_pizza_whole.png",  description: "まんまるホールピザから生まれたモンスター。チーズが最強の武器。", hp: 118, attack: 23, defense: 16, weakness: "ice",       attacks: '["charge","fire","wind"]' },
  { name: "ラーメンキング",   sprite_key: "monster_ramen.png",        description: "真っ赤な激辛スープが全身から吹き出す最強のラーメンモンスター。", hp: 120, attack: 50, defense: 14, weakness: "ice",       attacks: '["charge","fire","beam"]' },
  { name: "スシサーモン",     sprite_key: "monster_sushi.png",        description: "新鮮なサーモンをのせた寿司のモンスター。",               hp: 92,  attack: 17, defense: 11, weakness: "fire",      attacks: '["charge","ice","lightning"]' },
  { name: "タコヤッキー",     sprite_key: "monster_takoyaki.png",     description: "熱々の鉄板の上に並ぶたこ焼きのモンスター。",             hp: 96,  attack: 19, defense: 11, weakness: "wind",      attacks: '["charge","fire","shockwave"]' },
  { name: "ヤキザカナー",     sprite_key: "monster_yakizakana.png",   description: "じっくり焼かれた香ばしい焼き魚のモンスター。",           hp: 87,  attack: 16, defense: 9,  weakness: "shockwave", attacks: '["charge","shockwave","wind"]' }
].each do |attrs|
  monster = Monster.find_or_initialize_by(name: attrs[:name])
  monster.sprite_key = attrs[:sprite_key]
  monster.description = attrs[:description]
  monster.hp = attrs[:hp]
  monster.attack = attrs[:attack]
  monster.defense = attrs[:defense]
  monster.weakness = attrs[:weakness]
  monster.attacks = attrs[:attacks]
  monster.save!
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
