class RemoveUnlockMinLevelFromMonsters < ActiveRecord::Migration[7.1]
  def change
    remove_column :monsters, :unlock_min_level, :integer, default: 1, null: false
  end
end
