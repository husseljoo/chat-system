class UpdateApplicationJob < ApplicationJob
  queue_as :default

  def perform(token, name)
    application = Application.find_by(token: token)
    application.update(name: name)
  end
end
