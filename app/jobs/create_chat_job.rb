class CreateChatJob < ApplicationJob
  queue_as :default

  def perform(token, chat_number)
    application_id = Application.find_by(token: token)&.id
    puts "App Id:  #{application_id}"
    puts "Chat Number in ActiveJob:  #{chat_number}"

    chat = Chat.new(application_id: application_id, token: token, number: chat_number)
    if chat.save
      puts "Chat saved successfully"
    else
      puts "Error saving chat: #{chat.errors.full_messages.join(", ")}"
    end
  rescue StandardError => e
    puts "Error in CreateChatJob: #{e.message}"
  end
end
