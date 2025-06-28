class CreatePromiseParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :promise_participants do |t|
      t.references :promise,      foreign_key: true
      t.references :guest,        foreign_key: true
      t.integer :role,            null: false
      t.string :token,            null: false,  index: { unique: true }

      t.timestamps                null: false
    end
  end
end
