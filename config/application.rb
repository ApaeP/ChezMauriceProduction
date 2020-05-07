require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BookPA
  class Application < Rails::Application
    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Add the fonts and videos folder to assets compile
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("app", "assets", "videos")
    # config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/

    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    config.i18n.default_locale = :fr

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # Rails 5

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

  end
end

