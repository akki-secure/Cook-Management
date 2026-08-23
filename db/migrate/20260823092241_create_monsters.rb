class CreateMonsters < ActiveRecord::Migration[7.1]
  def change
    create_table :monsters do |t|
      t.string :name, null: false
      t.integer :rarity, default: 0, null: false
      t.string :sprite_key, null: false
      t.text :description
      t.integer :unlock_min_level, default: 1, null: false

      t.timestamps
    end
  end
end
