class RemoveAvatarKeyFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :avatar_key, :string, default: "chef_male", null: false
  end
end
