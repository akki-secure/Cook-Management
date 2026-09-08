class AddRainbowCoinsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :rainbow_coins, :integer, default: 0, null: false
  end
end
