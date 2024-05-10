class Chat < ApplicationRecord
  belongs_to :application, foreign_key: "token", primary_key: "token"
  has_many :messages
end
