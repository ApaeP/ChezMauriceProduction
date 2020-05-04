class AddNumberToVideo < ActiveRecord::Migration[6.0]
  def change
    add_column :videos, :number, :integer
  end
end
