class ContentPackage < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :product_id,         presence: true
  validates :user_id,            presence: true
  validates :linkedin_post,      presence: true
  validates :twitter_hook,       presence: true
  validates :email_subject,      presence: true
  validates :email_preview,      presence: true
  validates :promo_hook,         presence: true
  validates :community_question, presence: true
end
