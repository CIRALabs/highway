Rails.application.configure do
    config.cache_classes = false
    config.eager_load = false
    config.consider_all_requests_local       = false
    config.action_controller.perform_caching = true
    config.action_mailer.raise_delivery_errors = true
    config.active_support.deprecation = :log
    config.active_record.migration_error = :page_load
    config.assets.debug = true
    config.assets.digest = true
    config.assets.raise_runtime_errors = true
  
    config.action_mailer.smtp_settings = {
      :address => 'relay.cooperix.net',
      :port => '25',
      :enable_starttls_auto => true,
      :openssl_verify_mode => 'none'
    }
  
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.default_options = {from: 'mcr+minerva@sandelman.ca'}
end

AcmeKeys.acme.server="https://acme-staging-v02.api.letsencrypt.org/directory"

