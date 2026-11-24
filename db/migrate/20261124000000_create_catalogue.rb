class CreateCatalogue < ActiveRecord::Migration[8.1]
  def change
    create_table :realisations do |t|
      t.string :title
      t.text :description
      t.integer :position
      t.string :youtube_id
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.string :legacy_source
      t.string :legacy_id
      t.string :legacy_vimeo_url
      t.timestamps
      t.index [ :legacy_source, :legacy_id ], unique: true
      t.index [ :published, :position ]
    end

    create_table :categories do |t|
      t.string :name, null: false
      t.index :name, unique: true
    end

    create_join_table :categories, :realisations, column_options: { foreign_key: true } do |t|
      t.index [ :category_id, :realisation_id ], unique: true
      t.index :realisation_id
    end
  end
end
