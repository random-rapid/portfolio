class CreateEvidences < ActiveRecord::Migration[7.2]
  def change
    create_table :evidences do |t|
      t.references :promise, null: false, foreign_key: true

      t.timestamps
    end
  end
end
