class CreateProvinces < ActiveRecord::Migration[8.0]
  def change
    create_table :provinces do |t|
      t.references :kingdom, null: false, foreign_key: true
      t.string :loc
      t.string :name
      t.integer :land
      t.string :race
      t.integer :honor
      t.integer :nw
      t.boolean :protected

      t.timestamps
    end
  end
end
