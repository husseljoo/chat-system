class Chat < ApplicationRecord
  belongs_to :application, foreign_key: "token", primary_key: "token", counter_cache: true, dependent: :destroy
  has_many :message
end
