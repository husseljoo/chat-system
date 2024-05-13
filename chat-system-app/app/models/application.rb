class Application < ApplicationRecord
  has_many :chats, foreign_key: "token", primary_key: "token"
  validates :token, uniqueness: true
end
