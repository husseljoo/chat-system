class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.integer :chats_count, null: false, default: 0

      t.timestamps
    end
    add_index :applications, :token, unique: true # index for uniqueness validation
  end
end
