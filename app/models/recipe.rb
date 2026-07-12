class Recipe < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :ingredients, dependent: :destroy
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags

  has_one_attached :image

  accepts_nested_attributes_for :ingredients, allow_destroy: true,
            reject_if: ->(attrs) { attrs["name"].blank? }

  validates :title, presence: true
  validates :cooking_time, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :search_by_keyword, ->(keyword) {
    where("title LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(keyword)}%") if keyword.present?
  }
  scope :in_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :tagged_with, ->(tag_id) { joins(:tags).where(tags: { id: tag_id }) if tag_id.present? }
end
