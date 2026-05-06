require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:target_audience) }
    it { is_expected.to validate_presence_of(:content_goal) }

    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it { is_expected.to validate_length_of(:description).is_at_least(50).is_at_most(2000) }

    it "accepts valid content goals" do
      %w[awareness engagement conversion].each do |goal|
        product = build(:product, content_goal: goal)
        expect(product).to be_valid, "Expected #{goal} to be valid"
      end
    end

    it "rejects invalid content goals" do
      product = build(:product, content_goal: "viral")
      expect(product).not_to be_valid
      expect(product.errors[:content_goal]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:content_packages).dependent(:destroy) }
  end

  describe "dependent destroy" do
    it "destroys associated content packages when the product is destroyed" do
      product = create(:product)
      create(:content_package, product: product, user: product.user)
      expect { product.destroy }.to change(ContentPackage, :count).by(-1)
    end
  end
end
