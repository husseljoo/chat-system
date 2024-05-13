require 'swagger_helper'

RSpec.describe 'messages', type: :request do

  path '/applications/{application_token}/chats/{chat_number}/messages' do
    # You'll want to customize the parameter types...
    parameter name: 'application_token', in: :path, type: :string, description: 'application_token'
    parameter name: 'chat_number', in: :path, type: :string, description: 'chat_number'

    get('list messages') do
      response(200, 'successful') do
        let(:application_token) { '123' }
        let(:chat_number) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post('create message') do
      response(200, 'successful') do
        let(:application_token) { '123' }
        let(:chat_number) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/applications/{application_token}/chats/{chat_number}/messages/{number}' do
    # You'll want to customize the parameter types...
    parameter name: 'application_token', in: :path, type: :string, description: 'application_token'
    parameter name: 'chat_number', in: :path, type: :string, description: 'chat_number'
    parameter name: 'number', in: :path, type: :string, description: 'number'

    get('show message') do
      response(200, 'successful') do
        let(:application_token) { '123' }
        let(:chat_number) { '123' }
        let(:number) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    patch('update message') do
      response(200, 'successful') do
        let(:application_token) { '123' }
        let(:chat_number) { '123' }
        let(:number) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    put('update message') do
      response(200, 'successful') do
        let(:application_token) { '123' }
        let(:chat_number) { '123' }
        let(:number) { '123' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/all-messages' do

    get('all_messages message') do
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/search' do

    get('search message') do
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
