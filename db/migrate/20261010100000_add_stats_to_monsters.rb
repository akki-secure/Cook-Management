class AddStatsToMonsters < ActiveRecord::Migration[7.1]
  def change
    add_column :monsters, :defense, :integer, null: false, default: 10
    add_column :monsters, :weakness, :string
    add_column :monsters, :attacks, :string, null: false, default: '["charge","fire","beam"]'
  end
end
