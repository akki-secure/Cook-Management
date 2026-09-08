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
        type_label: monster.type_label
      }
    end

    @boss_stage_sprite_keys = %w[
      boss_hamburg_dark.png boss_hamburg_fire.png boss_hamburg_ice.png boss_hamburg_poison.png
    ]
  end
end
