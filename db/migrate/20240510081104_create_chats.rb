class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.belongs_to :application, null: false, foreign_key: true
      t.string :token, null: false
      # t.foreign_key :applications, column: :token, primary_key: :token
      t.integer :number, null: false
      t.integer :messages_count, null: false, default: 0

      t.timestamps
    end
  end
end
