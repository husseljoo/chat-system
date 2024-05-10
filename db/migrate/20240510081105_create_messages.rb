class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :body
      t.integer :number

      t.timestamps
    end
  end
end
