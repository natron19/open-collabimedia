require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:product)    { create(:product, user: user) }

  describe "GET /products" do
    context "when unauthenticated" do
      it "redirects to sign in" do
        get products_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in" do
      before { sign_in_as(user) }

      it "returns 200 and lists only the current user's products" do
        own_product   = create(:product, user: user, name: "My Product")
        other_product = create(:product, user: other_user, name: "Their Product")

        get products_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("My Product")
        expect(response.body).not_to include("Their Product")
      end
    end
  end

  describe "GET /products/new" do
    it "redirects unauthenticated visitor to sign in" do
      get new_product_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns 200 for signed-in user" do
      sign_in_as(user)
      get new_product_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /products" do
    before { sign_in_as(user) }

    let(:valid_params) do
      {
        product: {
          name:            "My Tool",
          description:     "This is a detailed description of my tool that helps people do things better and faster.",
          target_audience: "developers who want productivity",
          content_goal:    "awareness"
        }
      }
    end

    it "creates a product and redirects to show" do
      expect { post products_path, params: valid_params }.to change(Product, :count).by(1)
      expect(response).to redirect_to(product_path(Product.last))
      follow_redirect!
      expect(response.body).to include("Product created")
    end

    it "scopes the product to the current user" do
      post products_path, params: valid_params
      expect(Product.last.user).to eq(user)
    end

    it "re-renders new with 422 when description is blank" do
      post products_path, params: { product: valid_params[:product].merge(description: "") }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Description")
    end

    it "re-renders new with 422 when content_goal is invalid" do
      post products_path, params: { product: valid_params[:product].merge(content_goal: "viral") }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /products/:id" do
    it "redirects unauthenticated visitor to sign in" do
      get product_path(product)
      expect(response).to redirect_to(sign_in_path)
    end

    context "when signed in as the owner" do
      before { sign_in_as(user) }

      it "returns 200" do
        get product_path(product)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as another user" do
      it "returns 404" do
        sign_in_as(other_user)
        get product_path(product)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /products/:id" do
    before { sign_in_as(user) }

    it "updates the product and redirects to show" do
      patch product_path(product), params: { product: { name: "Updated Name" } }
      expect(response).to redirect_to(product_path(product))
      expect(product.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /products/:id" do
    before { sign_in_as(user) }

    it "destroys the product and redirects to index" do
      product_to_delete = create(:product, user: user)
      expect { delete product_path(product_to_delete) }.to change(Product, :count).by(-1)
      expect(response).to redirect_to(products_path)
    end

    it "destroys associated content packages" do
      pkg = create(:content_package, product: product, user: user)
      expect { delete product_path(product) }.to change(ContentPackage, :count).by(-1)
    end
  end
end
