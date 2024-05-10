class Chat < ApplicationRecord
  belongs_to :application, foreign_key: "token", primary_key: "token"
  # has_many :messages
  # has_many :messages, foreign_key: [:token, :number], primary_key: [:token, :number]
  has_many :messages, foreign_key: { query_constraints: [:chat_token, :chat_number] } #, dependent: :destroy
end
