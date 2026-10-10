class BattlesController < ApplicationController
  before_action :require_login

  def show
    @owned_monsters = current_user.user_monsters.includes(:monster).map do |user_monster|
      monster = user_monster.monster
      {
        name: monster.name,
        sprite_key: monster.sprite_key,
        hp: monster.hp,
        attack: monster.attack,
        defense: monster.defense,
        attacks: monster.attacks_array,
        weakness: monster.weakness,
        type_label: monster.type_label
      }
    end

    @boss_stages = [
      { sprite: "boss_hamburg_fire.png",   kind: "fire" },
      { sprite: "boss_hamburg_ice.png",    kind: "ice" },
      { sprite: "boss_hamburg_dark.png",   kind: "shockwave" }
    ]
  end
end
