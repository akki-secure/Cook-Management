class CreateGachaPulls < ActiveRecord::Migration[7.1]
  def change
    create_table :gacha_pulls do |t|
      t.references :user, null: false, foreign_key: true
      t.references :monster, null: true, foreign_key: true
      t.integer :cost, null: false
      t.boolean :hit, default: false, null: false

      t.timestamps
    end
  end
end
