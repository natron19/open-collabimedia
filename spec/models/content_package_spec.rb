require "rails_helper"

RSpec.describe ContentPackage, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:linkedin_post) }
    it { is_expected.to validate_presence_of(:twitter_hook) }
    it { is_expected.to validate_presence_of(:email_subject) }
    it { is_expected.to validate_presence_of(:email_preview) }
    it { is_expected.to validate_presence_of(:promo_hook) }
    it { is_expected.to validate_presence_of(:community_question) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:user) }
  end

  describe "user scoping" do
    it "is retrievable via user.content_packages" do
      user    = create(:user)
      product = create(:product, user: user)
      package = create(:content_package, product: product, user: user)
      expect(user.content_packages).to include(package)
    end

    it "is not retrievable via another user's content_packages" do
      user_a  = create(:user)
      user_b  = create(:user)
      product = create(:product, user: user_a)
      package = create(:content_package, product: product, user: user_a)
      expect(user_b.content_packages).not_to include(package)
    end
  end
end
