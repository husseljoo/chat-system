class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      # t.string :token, null: false
      # t.string :chat_number, null: false
      t.integer :chat_id, null: false
      t.text :body
      t.integer :number, null: false

      t.timestamps
    end
  end
end
