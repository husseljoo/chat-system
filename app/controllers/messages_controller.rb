require "net/http"

class MessagesController < ApplicationController
  before_action :set_message, only: %i[ show update destroy ]

  # GET /messages
  def index
    @messages = Message.all

    render json: @messages
  end

  # GET /messages/1
  def show
    render json: @message
  end

  # POST /messages
  def create
    token = params[:token]
    chat_number = params[:chat_number]
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

    CreateMessageJob.perform_later(token, chat_number, message_number)
    render json: { message_number: message_number }, status: :created
  end

  # PATCH/PUT /messages/1
  def update
    if @message.update(message_params)
      render json: @message
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  # DELETE /messages/1
  def destroy
    @message.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find(params[:id])
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
