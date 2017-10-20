require "sidekiq/web"

url = { url: "#{ENV['REDIS_URL']}" }

Sidekiq.configure_client do |config|
  config.redis = url
end

Sidekiq.configure_server do |config|
  config.redis = url
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  user == ENV.fetch('SIDEKIQ_USER') && password == ENV.fetch('SIDEKIQ_PASSWORD')
end