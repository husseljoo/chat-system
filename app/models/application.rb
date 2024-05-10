class Application < ApplicationRecord
  validates :token, uniqueness: true
end
