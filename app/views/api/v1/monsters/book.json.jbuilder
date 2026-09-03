json.array! @monsters do |monster|
  json.id monster.id
  json.name monster.name
  json.sprite_key monster.sprite_key
  json.description monster.description
  json.type_label monster.type_label
  json.animation_class monster.animation_class
  json.owned @owned_monster_ids.include?(monster.id)
end
