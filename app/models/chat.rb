class Chat < ApplicationRecord
  belongs_to :application
  # belongs_to :token, :foreign_key => "token", :class_name => "Application", :primary_key => "token"
  has_many :messages
  validates :token, uniqueness: true
end
