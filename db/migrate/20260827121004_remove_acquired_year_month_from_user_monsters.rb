class RemoveAcquiredYearMonthFromUserMonsters < ActiveRecord::Migration[7.1]
  def change
    remove_index :user_monsters, [ :user_id, :acquired_year_month ]
    remove_column :user_monsters, :acquired_year_month, :string
  end
end
