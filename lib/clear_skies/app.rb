module ClearSkies

  class App < Rails::Application
    routes.append do
      mount GreekFire::Engine => "/metrics"
    end

    # Enable cache classes. Production style.
    config.cache_classes = Rails.env.production?

    config.logger = Logger.new(STDOUT)
    config.log_level = :info
    config.action_view.logger = nil


    config.cache_store = :memory_store
    config.eager_load = Rails.env.production?

    # uncomment below to display errors
    config.consider_all_requests_local = !Rails.env.production?

    # Here you could remove some middlewares, for example
    # Rack::Lock, ActionDispatch::Flash and  ActionDispatch::BestStandardsSupport below.
    # The remaining stack is printed on rackup (for fun!).
    # Rails API has config.middleware.api_only! to get
    # rid of browser related middleware.
    config.middleware.delete "Rack::Lock"
    config.middleware.delete "ActionDispatch::Flash"
    config.middleware.delete "ActionDispatch::BestStandardsSupport"

    # We need a secret token for session, cookies, etc.
    config.secret_key_base = ENV['secret_key_base'] || SecureRandom.hex(64)
  end

  ClearSkies::App.initialize!
end
