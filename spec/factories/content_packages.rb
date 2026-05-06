FactoryBot.define do
  factory :content_package do
    association :product
    association :user
    linkedin_post      { "A compelling LinkedIn post about the product and the problem it solves for its target audience." }
    twitter_hook       { "A punchy Twitter thread opener under 280 characters that stands alone as a provocative statement." }
    email_subject      { "Try this new tool" }
    email_preview      { "A short preview text that complements the subject line and gives context without repeating it." }
    promo_hook         { "The hook headline. One supporting sentence about the outcome." }
    community_question { "What is the biggest challenge you face when trying to announce new features to your users?" }
    gemini_raw         { '{"linkedin_post":"A compelling LinkedIn post.","twitter_hook":"A punchy Twitter hook.","email_subject":"Try this","email_preview":"Short preview.","promo_hook":"Hook headline. One sentence.","community_question":"What challenge do you face?"}' }
  end
end
