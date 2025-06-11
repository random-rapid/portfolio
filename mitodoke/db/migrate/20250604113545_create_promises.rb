class CreatePromises < ActiveRecord::Migration[7.2]
  def change
    create_table :promises do |t|
      t.text :content,          null: false
      t.datetime :deadline,     null: false
      t.text :penalty,          null: false
      t.integer :progress
      t.integer :status
      t.datetime :accepted_at
      t.datetime :completed_at
      t.datetime :canceled_at
      t.datetime :witnessed_at
      
      t.timestamps              null: false
    end
  end
end
