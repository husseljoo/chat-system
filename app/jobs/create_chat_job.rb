require "net/http"

class CreateChatJob < ApplicationJob
  queue_as :default

  def perform(token, chat_number)
    # application_id = Application.find_by(token: token)&.id
    # puts "App Id:  #{application_id}"
    # puts "Chat Number in ActiveJob:  #{chat_number}"

    puts "INSIDE CreateChatJob, TOKEN:  #{token}, CHAT NUMBER:  #{chat_number}"
    url = "http://localhost:8081/message?app_token=#{token}&chat_number=#{chat_number}"
    puts "URL:  #{url}"
    res = set_token_redis(url)
    chat = Chat.new(token: token, number: chat_number)
    if chat.save
      puts "Chat saved successfully"
    else
      puts "Error saving chat: #{chat.errors.full_messages.join(", ")}"
    end
  rescue StandardError => e
    puts "Error in CreateChatJob: #{e.message}"
  end

  def set_token_redis(url)
    uri = URI(url)
    request = Net::HTTP::Put.new(uri)

    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        return true
      end
      return false
    rescue StandardError => e
      puts "Error: #{e.message}"
      return nil
    end
  end
end
