class CreateUserMonsters < ActiveRecord::Migration[7.1]
  def change
    create_table :user_monsters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :monster, null: false, foreign_key: true
      t.date :acquired_on, null: false
      t.string :acquired_year_month, null: false

      t.timestamps
    end
    add_index :user_monsters, [ :user_id, :acquired_year_month ], unique: true
  end
end
