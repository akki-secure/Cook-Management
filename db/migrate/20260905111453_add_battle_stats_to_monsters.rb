class AddBattleStatsToMonsters < ActiveRecord::Migration[7.1]
  def change
    add_column :monsters, :hp, :integer, null: false, default: 100
    add_column :monsters, :attack, :integer, null: false, default: 10
  end
end
