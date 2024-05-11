class CreateMessageJob < ApplicationJob
  queue_as :default

  def perform(token, chat_number, message_number)
    message = Message.new(token: token, chat_number: chat_number, number: message_number)

    if message.save
      puts "Message saved successfully"
    else
      puts "Error saving message: #{message.errors.full_messages.join(", ")}"
    end
  end
end
