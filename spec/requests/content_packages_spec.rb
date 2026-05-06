require "rails_helper"

RSpec.describe "ContentPackages", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:product)    { create(:product, user: user) }

  VALID_GEMINI_JSON = {
    linkedin_post:      "A compelling LinkedIn post specific to this product.",
    twitter_hook:       "A punchy Twitter hook under 280 characters.",
    email_subject:      "Try this",
    email_preview:      "Here is why you should try this product today and how it will help you.",
    promo_hook:         "The headline. One supporting sentence.",
    community_question: "What is your biggest challenge when trying to do X in your work?"
  }.to_json

  describe "POST /products/:product_id/content_packages" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        post product_content_packages_path(product)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as the product owner" do
      before { sign_in_as(user) }

      context "when Gemini returns valid JSON" do
        before { gemini_returns(VALID_GEMINI_JSON) }

        it "creates a ContentPackage and redirects to show" do
          expect { post product_content_packages_path(product) }
            .to change(ContentPackage, :count).by(1)
          expect(response).to redirect_to(
            product_content_package_path(product, ContentPackage.last)
          )
        end

        it "calls GeminiService with the correct template and variables" do
          expect(GeminiService).to receive(:generate).with(
            template: "collabimedia_content_package_v1",
            variables: {
              product_name:        product.name,
              description:         product.description,
              target_audience:     product.target_audience,
              content_goal:        product.content_goal,
              custom_instructions: ""
            }
          ).and_return(VALID_GEMINI_JSON)

          post product_content_packages_path(product)
        end

        it "stores gemini_raw on the created package" do
          post product_content_packages_path(product)
          expect(ContentPackage.last.gemini_raw).to eq(VALID_GEMINI_JSON)
        end

      end

      context "when Gemini returns non-JSON text" do
        before do
          allow(GeminiService).to receive(:generate).and_return("Sorry, I cannot do that.")
        end

        it "does not create a ContentPackage" do
          expect { post product_content_packages_path(product) }
            .not_to change(ContentPackage, :count)
        end

        it "re-renders product show with a JSON error message" do
          post product_content_packages_path(product)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("not valid JSON")
        end
      end

      context "when GeminiService raises GeminiError" do
        before { gemini_raises(GeminiService::GeminiError) }

        it "does not create a ContentPackage" do
          expect { post product_content_packages_path(product) }
            .not_to change(ContentPackage, :count)
        end

        it "renders the ai_error partial" do
          post product_content_packages_path(product)
          expect(response.body).to include("Something went wrong")
        end
      end

      context "when GeminiService raises BudgetExceededError" do
        before { gemini_raises(GeminiService::BudgetExceededError) }

        it "renders the budget-exceeded error partial" do
          post product_content_packages_path(product)
          expect(response.body).to include("daily AI request limit")
        end
      end
    end

    context "when signed in as another user" do
      it "returns 404" do
        sign_in_as(other_user)
        post product_content_packages_path(product)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /products/:product_id/content_packages/:id" do
    let(:package) { create(:content_package, product: product, user: user) }

    it "redirects unauthenticated visitor to sign in" do
      get product_content_package_path(product, package)
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "returns 200" do
        get product_content_package_path(product, package)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as another user" do
      it "returns 404" do
        sign_in_as(other_user)
        get product_content_package_path(product, package)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /products/:product_id/content_packages/:id" do
    let!(:package) { create(:content_package, product: product, user: user) }

    before { sign_in_as(user) }

    it "destroys the package and redirects to product show" do
      expect { delete product_content_package_path(product, package) }
        .to change(ContentPackage, :count).by(-1)
      expect(response).to redirect_to(product_path(product))
    end
  end
end
