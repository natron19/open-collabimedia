FactoryBot.define do
  factory :product do
    association :user
    sequence(:name) { |n| "Product #{n}" }
    description     { "This is a detailed product description that explains what the product does, who it helps, and what makes it different from alternatives on the market." }
    target_audience { "indie SaaS founders who ship fast" }
    content_goal    { "awareness" }

    trait :engagement do
      content_goal { "engagement" }
    end

    trait :conversion do
      content_goal { "conversion" }
    end
  end
end
