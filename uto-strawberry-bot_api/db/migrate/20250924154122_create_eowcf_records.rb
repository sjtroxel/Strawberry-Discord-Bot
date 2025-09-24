class CreateEowcfRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :eowcf_records do |t|
      t.references :kingdom, null: false, foreign_key: true
      t.string :loc
      t.datetime :eowcf_start
      t.datetime :eowcf_end
      t.datetime :detected_at
      t.string :reason

      t.timestamps
    end
  end
end
