require "net/http"

class ChatsController < ApplicationController
  before_action :set_chat, only: %i[ show update destroy ]

  # GET /chats
  def index
    @chats = Chat.all

    render json: @chats
  end

  # GET /chats/1
  def show
    render json: @chat
  end

  # POST /chats
  def create
    token = params[:token]
    puts "TOKEN:  #{token}"
    url = "http://localhost:8081/chat?app_token=#{token}"
    puts "URL:  #{url}"
    chat_number = fetch_chat_number(url, "POST")
    puts "Chat Number:  #{chat_number}"
    if chat_number.nil?
      render json: { error: "Failed to find application with token '#{token}'" }, status: :unprocessable_entity
      return
    end

    CreateChatJob.perform_later(token, chat_number)
    render json: { chat_number: chat_number }, status: :created
  end

  # PATCH/PUT /chats/1
  def update
    if @chat.update(chat_params)
      render json: @chat
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
  end

  # DELETE /chats/1
  def destroy
    @chat.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = Chat.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def chat_params
    params.fetch(:chat, {})
  end

  def fetch_chat_number(url, method)
    uri = URI(url)

    if method.upcase == "POST"
      request = Net::HTTP::Post.new(uri)
    elsif method.upcase == "GET"
      request = Net::HTTP::Get.new(uri)
    else
      puts "Invalid method. Please specify either 'POST' or 'GET'."
      return nil
    end

    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        body = JSON.parse(response.body)
        return body["chat_number"]
      else
        puts "Error: #{response.code} - #{response.message}"
        return nil
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
      return nil
    end
  end
end
