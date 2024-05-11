# inside config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6379/2"),
  }
end
Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6379/2"),
  }
end
