Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6379/1"),
  }
end
