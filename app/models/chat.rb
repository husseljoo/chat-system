class Chat < ApplicationRecord
  belongs_to :application
  belongs_to :token, :foreign_key => "number", :class_name => "Application", :primary_key => "token"
end
