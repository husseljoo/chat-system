require "net/http"
require "securerandom"

class ApplicationsController < ApplicationController
  before_action :set_application, only: %i[ show update destroy ]

  # GET /applications
  def index
    @applications = Application.all

    render json: @applications
  end

  # GET /applications/:token
  def show
    render json: @application.as_json(except: [:created_at, :updated_at])
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

    base_url = ENV["SEQUENCE_GENERATOR_URL"] || "http://localhost:8081"
    url = "#{base_url}/chat?app_token=#{token}"
    puts "URL:  #{url}"
    res = set_token_redis(url)
    puts "Res:  #{res}"
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
    if @application.update(application_params)
      # render json: @application
      render json: @application.as_json(except: [:created_at, :updated_at])
    else
      render json: @application.errors, status: :unprocessable_entity
    end
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
