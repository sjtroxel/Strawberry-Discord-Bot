class CreateKingdomSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :kingdom_snapshots do |t|
      t.references :kingdom, null: false, foreign_key: true
      t.string :loc
      t.datetime :snapshot_time
      t.integer :total_land
      t.integer :total_honor
      t.json :provinces, default: {}

      t.timestamps
    end
  end
end
