class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :name
      t.string :description
      t.string :location
      t.string :ews_item_id
      t.string :target_mailbox
      t.text :attendee_addresses
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.timestamps
    end
  end
  
  def self.down
    drop_table :events
  end
end
