class Message < ApplicationRecord
  # belongs_to :chat
  # belongs_to :chat, foreign_key: [:token, :number], primary_key: [:token, :number]
  has_many :chat, foreign_key: { query_constraints: [:token, :number] } #, dependent: :destroy
end
