require "net/http"

class MessagesController < ApplicationController
  before_action :set_message, only: %i[ show update destroy ]

  def all_messages
    @messages = Message.all
    render json: @messages
  end

  # GET /applications/{application_token}/chats/{chat_number}/messages
  def index
    query = params[:query]
    if query.present?
      puts "query:  #{query}, inside message_controller!"
      search_messages_by_query
      return
    end

    @chat = Chat.find_by(token: params[:application_token], number: params[:chat_number])

    if @chat.nil?
      render json: { error: "Chat not found" }, status: :not_found
      return
    end

    @messages = Message.where(chat_id: @chat.id)
    render json: @messages.as_json(only: [:number, :body])
  end

  # GET /messages/1
  def show
    render json: @message
  end

  # POST /applications/{application_token}/chats/{chat_number}/messages
  def create
    token = params[:application_token]
    chat_number = params[:chat_number]
    body = params[:body]
    puts "body:  #{body}"
    puts "TOKEN:  #{token}, CHAT NUMBER:  #{chat_number}"

    base_url = ENV["SEQUENCE_GENERATOR_URL"] || "http://localhost:8081"
    url = "#{base_url}/message?app_token=#{token}&chat_number=#{chat_number}"
    puts "Message URL:  #{url}"
    message_number = fetch_message_number(url, "POST")
    puts "Message Number:  #{message_number}"
    if message_number.nil?
      render json: { error: "Failed to find application with token '#{token}' and chat_number '#{chat_number}'" }, status: :unprocessable_entity
      return
    end

    CreateMessageJob.perform_later(token, chat_number, message_number, body)
    render json: { message_number: message_number }, status: :created
  end

  # PATCH/PUT /applications/{application_token}/chats/{chat_number}/messages/{number}
  def update
    body = params[:body]
    if body.nil? || body.empty?
      render json: { error: "You need to pass a non-empty 'body' paramater to update message accordingly." }, status: :unprocessable_entity
      return
    end
    if @message.update(body: params[:body])
      render json: @message
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  def search_messages_by_query
    token = params[:application_token]
    chat_number = params[:chat_number]
    query = params[:query]
    if token.blank? || chat_number.blank? || query.blank?
      render json: { error: "Missing parameters. Please provide token, chat_number, and query." }, status: :unprocessable_entity
      return
    end

    unless chat = Chat.find_by(token: token, number: chat_number)
      render json: { error: "Failed to find chat with token '#{token}' and chat_number '#{chat_number}'" }, status: :unprocessable_entity
      return
    end
    puts "CHAT.ID:  #{chat.id}"

    begin
      messages = Message.search_body(query, chat.id)
      render json: messages
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      render json: { error: "Elasticsearch error: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end
  end

  # DELETE /messages/1
  def destroy
    @message.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find_by(number: params[:number], chat_id: Chat.find_by(token: params[:application_token], number: params[:chat_number])&.id)
  end

  # Only allow a list of trusted parameters through.
  def message_params
    params.fetch(:message, {})
  end

  def fetch_message_number(url, method)
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
        return body["message_number"]
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