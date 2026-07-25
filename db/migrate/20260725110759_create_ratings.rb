class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.integer :score, null: false

      t.timestamps
    end
    add_index :ratings, [ :user_id, :recipe_id ], unique: true
  end
end
