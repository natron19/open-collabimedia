class Product < ApplicationRecord
  belongs_to :user
  has_many :content_packages, dependent: :destroy

  validates :name,            presence: true, length: { maximum: 100 }
  validates :description,     presence: true, length: { minimum: 50, maximum: 2000 }
  validates :target_audience, presence: true, length: { maximum: 150 }
  validates :content_goal,    presence: true,
                              inclusion: { in: %w[awareness engagement conversion] }
end
