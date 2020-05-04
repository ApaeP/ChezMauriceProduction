class DeleteFieldsFromContact < ActiveRecord::Migration[6.0]
  def change
    change_table(:contacts) do |t|
      t.remove :phone
      t.remove :company
      t.remove :known_from
    end
  end
end
