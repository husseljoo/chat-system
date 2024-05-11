class Message < ApplicationRecord
  include Searchable
  belongs_to :chat #, counter_cache: true
  def self.search(query, chat_id)
    query = "*#{query}*"
    search_definition = {
      query: {
        bool: {
          must: [
            { match: { body: { query: query, fuzziness: "auto" } } },
            { match: { chat_id: chat_id } },
          ],
        },
      },
    }
    __elasticsearch__.search(search_definition)
  end
end
