class AddGamificationToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :level, :integer, default: 1, null: false
    add_column :users, :exp, :integer, default: 0, null: false
    add_column :users, :current_streak_days, :integer, default: 0, null: false
    add_column :users, :longest_streak_days, :integer, default: 0, null: false
    add_column :users, :last_activity_on, :date
    # titlesテーブルはこの後のマイグレーションで作成されるため、外部キー制約は
    # add_foreign_key_to_users_current_title migrationで別途付与する
    add_column :users, :current_title_id, :bigint
    add_index :users, :current_title_id
  end
end
