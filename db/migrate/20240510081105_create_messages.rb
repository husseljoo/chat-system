class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.belongs_to :chat, null: false, foreign_key: true
      t.string :chat_number, null: false
      t.text :body
      t.integer :number, null: false

      t.timestamps
    end
  end
end
