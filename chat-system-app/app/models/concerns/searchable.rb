module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    mapping do
      indexes :body, type: :text, analyzer: "english"  # Enable full-text search with analyzer
      indexes :chat_id, type: :integer  # Include chat_id for filtering
    end
    def self.search(query)
      self.__elasticsearch__.search(query)
    end
  end
end
