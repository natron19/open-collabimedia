class ContentPackagesController < ApplicationController
  before_action :set_product

  rate_limit to: 10, within: 1.minute, only: [:create],
             with: -> { redirect_to @product, alert: "Please wait before generating again." }

  def index
    redirect_to @product
  end

  def create
    custom = params[:custom_instructions].to_s.strip
    custom_instructions = custom.present? ? "Additional instructions from the creator:\n#{custom}" : ""

    raw_response = GeminiService.generate(
      template:  "collabimedia_content_package_v1",
      variables: {
        product_name:        @product.name,
        description:         @product.description,
        target_audience:     @product.target_audience,
        content_goal:        @product.content_goal,
        custom_instructions: custom_instructions
      }
    )

    parsed = parse_gemini_json(raw_response)

    @content_package = current_user.content_packages.build(
      product:            @product,
      linkedin_post:      parsed["linkedin_post"],
      twitter_hook:       parsed["twitter_hook"],
      email_subject:      parsed["email_subject"],
      email_preview:      parsed["email_preview"],
      promo_hook:         parsed["promo_hook"],
      community_question: parsed["community_question"],
      gemini_raw:         raw_response
    )

    if @content_package.save
      redirect_to product_content_package_path(@product, @content_package),
                  notice: "Content package generated."
    else
      flash.now[:alert] = "Could not save the generated package."
      @content_packages = @product.content_packages.order(created_at: :desc)
      render "products/show", status: :unprocessable_entity
    end

  rescue JSON::ParserError
    flash.now[:alert] = "The response was not valid JSON. Please try again."
    @content_packages = @product.content_packages.order(created_at: :desc)
    render "products/show", status: :unprocessable_entity
  rescue GeminiService::BudgetExceededError
    render "shared/ai_error_page", locals: { error_type: :budget_exceeded }, status: :unprocessable_entity
  rescue GeminiService::GatekeeperError
    render "shared/ai_error_page", locals: { error_type: :gatekeeper_blocked }, status: :unprocessable_entity
  rescue GeminiService::TimeoutError
    render "shared/ai_error_page", locals: { error_type: :timeout }, status: :unprocessable_entity
  rescue GeminiService::GeminiError
    render "shared/ai_error_page", locals: { error_type: :error }, status: :unprocessable_entity
  end

  def show
    @content_package = current_user.content_packages.find(params[:id])
  end

  def destroy
    @content_package = current_user.content_packages.find(params[:id])
    @content_package.destroy
    redirect_to @product, notice: "Package deleted."
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
  end

  def parse_gemini_json(raw)
    Rails.logger.debug("[parse_gemini_json] raw (#{raw.bytesize}B): #{raw.truncate(500)}")
    # Strip all markdown fences wherever they appear, then find the
    # outermost {...} block via first { and last }.
    cleaned = raw.gsub(/```(?:json)?\s*/, "").gsub(/```/, "").strip
    start  = cleaned.index("{")
    finish = cleaned.rindex("}")
    raise JSON::ParserError, "No JSON object found in response" unless start && finish
    JSON.parse(cleaned[start..finish])
  end
end
