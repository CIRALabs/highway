# RAVEN specific configuration (.dsn) has been moved to environment/production.rb
# on the target machines themselves. With .dsn, raven will not be enabled.
Raven.configure do |config|
  #config.dsn = 'https://184818fffd53434eb0c7e555016558de:adfecbb2123b40c88df38f2bb9bd76fb@sentry.io/1488540'

  config.environments = ['production']
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.silence_ready = true
end
