require "net/http"
require "securerandom"

class ApplicationsController < ApplicationController
  before_action :set_application, only: %i[ show update destroy ]
  SEQUENCE_GENERATOR_URL = ENV["SEQUENCE_GENERATOR_URL"] || "http://localhost:8081"

  # GET /applications
  def index
    @applications = Application.all

    render json: @applications
  end

  # GET /applications/:token
  def show
    render json: @application.as_json(only: [:token, :name, :chats_count])
    # render json: @application
  end

  # POST /applications?name=app_name
  def create
    token = generate_token
    name = params[:name]
    if name.nil? || name.empty?
      render json: { error: "No name given as paramater!" }, status: :unprocessable_entity
      return
    end

    url = "#{SEQUENCE_GENERATOR_URL}/chat?app_token=#{token}"
    res = set_token_redis(url)
    if res.nil? || res == false
      render json: { error: "Failed to set token: #{token}" }, status: :unprocessable_entity
      return
    end

    @application = Application.new(application_params.merge(token: token))

    if @application.save
      # render json: @application, status: :created, location: @application
      render json: { token: token }, status: :created, location: @application
    else
      render json: @application.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /applications/:token
  # Check in redis first in order to not clutter DB
  def update
    name = params[:name]
    if name.nil? || name.empty?
      render json: { error: "No name given as paramater!" }, status: :unprocessable_entity
      return
    end
    token = params[:token]
    #check in redis first
    url = "#{SEQUENCE_GENERATOR_URL}/chat?app_token=#{token}"
    res = application_exists(url)
    unless res
      render json: { error: "Failed to find application with token '#{token}'" }, status: :not_found
      return
    end
    UpdateApplicationJob.perform_later(token, name)
    render json: { message: "Update operation in progress. Application name will be updated shortly." }, status: :accepted
  end

  # DELETE /applications/:token
  def destroy
    @application.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_application
    @application = Application.find_by(token: params[:token])
  end

  # Only allow a list of trusted parameters through.
  # def application_params
  #   params.fetch(:application, {})
  # end

  def application_params
    params.permit(:name)
  end

  def generate_token(length = 12)
    SecureRandom.alphanumeric(length)
  end

  def application_exists(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)

    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        return true
      else
        puts "Error: #{response.code} - #{response.message}"
        return false
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
      return false
    end
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
