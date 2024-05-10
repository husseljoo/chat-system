class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.string :token, null: false
      t.integer :number, null: false
      t.integer :messages_count, null: false, default: 0

      t.timestamps
    end
  end
end
