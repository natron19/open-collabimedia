class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,            null: false, limit: 100
      t.text    :description,     null: false
      t.string  :target_audience, null: false, limit: 150
      t.string  :content_goal,    null: false
      t.timestamps null: false
    end
  end
end
