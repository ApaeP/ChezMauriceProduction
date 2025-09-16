class RemoveVideoNames < ActiveRecord::Migration[7.2]
  def change
    remove_column :videos, :name, :string
  end
end
