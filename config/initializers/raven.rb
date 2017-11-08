# RAVEN specific configuration (.dsn) has been moved to environment/production.rb
# on the target machines themselves. With .dsn, raven will not be enabled.
Raven.configure do |config|
  #config.dsn = 'https://f41344c937b54f47a8efca8550f09942:7c5b1cd8ad0145e08781d49bfc6fbcac@sentry.io/241989'

  config.environments = ['production']
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.silence_ready = true
end
