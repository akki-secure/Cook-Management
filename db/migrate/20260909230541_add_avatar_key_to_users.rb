class AddAvatarKeyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :avatar_key, :string, default: "chef_male", null: false
  end
end
