class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :chat_number, :foreign_key => "chat_number", :class_name => "Application", :primary_key => "number"
end
