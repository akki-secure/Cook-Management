class CreateTitles < ActiveRecord::Migration[7.1]
  def change
    create_table :titles do |t|
      t.string :name, null: false
      t.integer :min_level, null: false
      t.integer :rank, null: false

      t.timestamps
    end
    add_index :titles, :min_level, unique: true
    add_index :titles, :rank, unique: true
  end
end
