class Application < ApplicationRecord
  has_many :chats
  validates :token, uniqueness: true
end
