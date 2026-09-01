# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_09_01_114815) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "coin_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source_type", null: false
    t.bigint "source_id"
    t.integer "amount", null: false
    t.date "occurred_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "occurred_on"], name: "index_coin_events_on_user_id_and_occurred_on"
    t.index ["user_id", "source_type", "source_id"], name: "index_coin_events_on_user_and_source", unique: true
    t.index ["user_id"], name: "index_coin_events_on_user_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "created_at"], name: "index_comments_on_recipe_id_and_created_at"
    t.index ["recipe_id"], name: "index_comments_on_recipe_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "exp_events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source_type", null: false
    t.bigint "source_id"
    t.integer "amount", null: false
    t.date "occurred_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "occurred_on"], name: "index_exp_events_on_user_id_and_occurred_on"
    t.index ["user_id", "source_type", "source_id"], name: "index_exp_events_on_user_and_source", unique: true
    t.index ["user_id"], name: "index_exp_events_on_user_id"
  end

  create_table "favorites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_favorites_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_favorites_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "gacha_pulls", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "monster_id"
    t.integer "cost", null: false
    t.boolean "hit", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["monster_id"], name: "index_gacha_pulls_on_monster_id"
    t.index ["user_id"], name: "index_gacha_pulls_on_user_id"
  end

  create_table "ingredients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "quantity"
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_ingredients_on_recipe_id"
  end

  create_table "monsters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "rarity", default: 0, null: false
    t.string "sprite_key", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ratings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.integer "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_ratings_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_ratings_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "recipe_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "tag_id"], name: "index_recipe_tags_on_recipe_id_and_tag_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_tags_on_recipe_id"
    t.index ["tag_id"], name: "index_recipe_tags_on_tag_id"
  end

  create_table "recipes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "instructions"
    t.integer "cooking_time"
    t.integer "servings"
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_recipes_on_category_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "titles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "min_level", null: false
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["min_level"], name: "index_titles_on_min_level", unique: true
    t.index ["rank"], name: "index_titles_on_rank", unique: true
  end

  create_table "user_monsters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "monster_id", null: false
    t.date "acquired_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["monster_id"], name: "index_user_monsters_on_monster_id"
    t.index ["user_id"], name: "index_user_monsters_on_user_id"
  end

  create_table "user_titles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "title_id", null: false
    t.date "awarded_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title_id"], name: "index_user_titles_on_title_id"
    t.index ["user_id"], name: "index_user_titles_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level", default: 1, null: false
    t.integer "exp", default: 0, null: false
    t.integer "current_streak_days", default: 0, null: false
    t.integer "longest_streak_days", default: 0, null: false
    t.date "last_activity_on"
    t.bigint "current_title_id"
    t.integer "coins", default: 0, null: false
    t.index ["current_title_id"], name: "index_users_on_current_title_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "coin_events", "users"
  add_foreign_key "comments", "recipes"
  add_foreign_key "comments", "users"
  add_foreign_key "exp_events", "users"
  add_foreign_key "favorites", "recipes"
  add_foreign_key "favorites", "users"
  add_foreign_key "gacha_pulls", "monsters"
  add_foreign_key "gacha_pulls", "users"
  add_foreign_key "ingredients", "recipes"
  add_foreign_key "ratings", "recipes"
  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_tags", "recipes"
  add_foreign_key "recipe_tags", "tags"
  add_foreign_key "recipes", "categories"
  add_foreign_key "recipes", "users"
  add_foreign_key "user_monsters", "monsters"
  add_foreign_key "user_monsters", "users"
  add_foreign_key "user_titles", "titles"
  add_foreign_key "user_titles", "users"
  add_foreign_key "users", "titles", column: "current_title_id"
end
