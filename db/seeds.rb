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

[
  { name: "レッドトマトン",       sprite_key: "color:red;shape:circle",     unlock_min_level: 1,  description: "真っ赤なトマトのようなまん丸モンスター。" },
  { name: "オレンジキャロッタ",   sprite_key: "color:orange;shape:triangle", unlock_min_level: 1,  description: "にんじんを思わせる三角形のモンスター。" },
  { name: "イエローレモニー",     sprite_key: "color:yellow;shape:square",  unlock_min_level: 1,  description: "レモンのように爽やかな四角いモンスター。" },
  { name: "グリーンキャベジオ",   sprite_key: "color:green;shape:circle",   unlock_min_level: 10, description: "キャベツを思わせる緑色のモンスター。" },
  { name: "ブルーオニオス",       sprite_key: "color:blue;shape:triangle",  unlock_min_level: 10, description: "涙が出そうな青い三角モンスター。" },
  { name: "パープルナスビー",     sprite_key: "color:purple;shape:square",  unlock_min_level: 25, description: "なすのような紫の四角モンスター。" },
  { name: "ゴールドライサー",     sprite_key: "color:gold;shape:star",      unlock_min_level: 40, description: "黄金に輝く星形のモンスター。" },
  { name: "シルバーフィッシュン", sprite_key: "color:silver;shape:star",    unlock_min_level: 60, description: "銀色に光る星形のモンスター。" },
  { name: "レインボーシェフキング", sprite_key: "color:rainbow;shape:crown", unlock_min_level: 75, description: "虹色の王冠を戴くモンスター。" },
  { name: "ダイヤモンドグルメット", sprite_key: "color:diamond;shape:crown", unlock_min_level: 90, description: "ダイヤモンドのように輝く王冠モンスター。" }
].each do |attrs|
  Monster.find_or_create_by!(name: attrs[:name]) do |m|
    m.sprite_key = attrs[:sprite_key]
    m.unlock_min_level = attrs[:unlock_min_level]
    m.description = attrs[:description]
  end
end
