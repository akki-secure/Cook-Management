class CreateCoinEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :coin_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_type, null: false
      t.bigint :source_id
      t.integer :amount, null: false
      t.date :occurred_on, null: false

      t.timestamps
    end
    add_index :coin_events, [ :user_id, :occurred_on ]
    add_index :coin_events, [ :user_id, :source_type, :source_id ], unique: true, name: "index_coin_events_on_user_and_source"
  end
end
