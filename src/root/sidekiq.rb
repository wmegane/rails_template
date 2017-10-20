url = { url: "#{ENV['REDIS_URL']}" }

Sidekiq.configure_client do |config|
  config.redis = url
end

Sidekiq.configure_server do |config|
  config.redis = url
end