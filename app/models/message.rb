class Message < ApplicationRecord
  include Searchable
  belongs_to :chat #, counter_cache: true
  def self.search_body(query, chat_id)
    search_definition = {
      query: {
        bool: {
          must: [
            { match: { body: { query: query } } },
            { match: { chat_id: chat_id } },
          ],
        },
      },
      _source: ["body", "number"],
    }
    __elasticsearch__.search(search_definition)
  end
end
