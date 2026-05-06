class CreateContentPackages < ActiveRecord::Migration[8.1]
  def change
    create_table :content_packages, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :user,    null: false, foreign_key: true, type: :uuid
      t.text :linkedin_post,       null: false
      t.text :twitter_hook,        null: false
      t.string :email_subject,     null: false
      t.text :email_preview,       null: false
      t.text :promo_hook,          null: false
      t.text :community_question,  null: false
      t.text :gemini_raw
      t.timestamps null: false
    end

    add_index :content_packages, :created_at
  end
end
