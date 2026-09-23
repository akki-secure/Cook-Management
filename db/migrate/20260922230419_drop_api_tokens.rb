class DropApiTokens < ActiveRecord::Migration[7.1]
  def change
    drop_table :api_tokens, force: :cascade do |t|
      t.bigint "user_id", null: false
      t.string "token_digest", null: false
      t.datetime "last_used_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "token_digest" ], name: "index_api_tokens_on_token_digest", unique: true
      t.index [ "user_id" ], name: "index_api_tokens_on_user_id"
    end
  end
end
