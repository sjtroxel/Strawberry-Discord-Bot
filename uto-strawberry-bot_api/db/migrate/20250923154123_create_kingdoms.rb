class CreateKingdoms < ActiveRecord::Migration[8.0]
  def change
    create_table :kingdoms do |t|
      t.string :loc
      t.string :name
      t.string :stance
      t.integer :honor
      t.integer :nw

      t.timestamps
    end
  end
end
