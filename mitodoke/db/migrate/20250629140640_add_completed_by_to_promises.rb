class AddCompletedByToPromises < ActiveRecord::Migration[7.2]
  def change
    add_column :promises, :completed_by, :string
  end
end
