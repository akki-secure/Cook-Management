class AddForeignKeyToUsersCurrentTitle < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :users, :titles, column: :current_title_id
  end
end
