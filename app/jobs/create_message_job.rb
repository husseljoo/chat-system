class CreateMessageJob < ApplicationJob
  queue_as :default

  def perform(token, chat_number, message_number)
    message = Message.create!(number: message_number, chat: Chat.where(token: token, number: chat_number).limit(1).select(:id).take)

    if message.persisted?
      puts "Message saved successfully with ID: #{message.id}"
    else
      puts "Error saving message: #{message.errors.full_messages.join(", ")}"
    end
  end
end
