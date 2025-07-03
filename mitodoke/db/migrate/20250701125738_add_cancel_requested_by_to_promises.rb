class AddCancelRequestedByToPromises < ActiveRecord::Migration[7.2]
  def change
    add_column :promises, :cancel_requested_by, :string
  end
end
