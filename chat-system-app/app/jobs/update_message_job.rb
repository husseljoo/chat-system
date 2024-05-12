class UpdateMessageJob < ApplicationJob
  queue_as :default

  def perform(token, chat_number, message_number, body)
    chat = Chat.find_by(token: token, number: chat_number)
    message = Message.find_by(id: chat.id, number: message_number)
    # message = Chat.find_by(token: token, number: chat_number)
    #              .try(:messages, &:find_by, number: message_number)
    message.update(body: body)
  end
end
