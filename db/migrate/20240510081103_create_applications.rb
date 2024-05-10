class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.string :name
      t.string :token
      t.integer :chats_count

      t.timestamps
    end
  end
end
