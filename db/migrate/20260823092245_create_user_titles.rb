class CreateUserTitles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_titles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :title, null: false, foreign_key: true
      t.date :awarded_on, null: false

      t.timestamps
    end
  end
end
