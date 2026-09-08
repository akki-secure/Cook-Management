json.array! @user_monsters do |user_monster|
  monster = user_monster.monster
  json.id monster.id
  json.name monster.name
  json.sprite_key monster.sprite_key
  json.description monster.description
  json.hp monster.hp
  json.attack monster.attack
  json.type_label monster.type_label
  json.acquired_on user_monster.acquired_on
end
