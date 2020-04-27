class AddKnownfromToContact < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :known_from, :string
  end
end
