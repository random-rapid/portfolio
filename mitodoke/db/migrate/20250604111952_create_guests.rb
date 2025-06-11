class CreateGuests < ActiveRecord::Migration[7.2]
  def change
    create_table :guests do |t|
      t.string :family_name,  null: false
      t.string :given_name,   null: false
      t.string :handle_name,                index: { unique: true }
      t.string :email,        null: false,  index: { unique: true }

      t.timestamps            null: false
    end
  end
end
