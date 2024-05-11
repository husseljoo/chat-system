config = {
  host: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200/"),
  transport_options: {
    request: { timeout: 5 },
  },
}

Elasticsearch::Model.client = Elasticsearch::Client.new(config)
