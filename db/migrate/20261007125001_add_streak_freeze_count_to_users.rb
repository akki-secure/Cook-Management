class AddStreakFreezeCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :streak_freeze_count, :integer, default: 1, null: false
  end
end
