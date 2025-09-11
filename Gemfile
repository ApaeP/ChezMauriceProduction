source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.9'

# Core Rails - Version intermédiaire plus stable
gem 'rails', '~> 7.2.0'

# Database
gem 'pg', '>= 0.18', '< 2.0'

# Server
gem 'puma', '~> 6.0'

# Asset Pipeline & Frontend
gem 'sprockets-rails' # Asset pipeline for Rails
gem 'sass-rails', '>= 6'
gem 'image_processing', '~> 1.2' # Active Storage image processing

# JavaScript & CSS - Gardons importmap pour la modernité
gem 'importmap-rails' # Modern JS without Node.js
gem 'turbo-rails'     # Hotwire's SPA-like page accelerator
gem 'stimulus-rails'  # Hotwire's modest JavaScript framework

# Build JSON APIs
gem 'jbuilder'

# Use Redis for Action Cable, caching, and background jobs
gem 'redis', '~> 5.0'

# Reduces boot times through caching
gem 'bootsnap', require: false

# Authentication
gem 'devise'

# Forms & UI
gem 'simple_form'

# CSS Framework
gem 'autoprefixer-rails'
gem 'font-awesome-sass'

# File uploads & processing
gem 'cloudinary'

# Video integration
gem 'has_vimeo_video'

# Security & CORS
gem 'rack-cors'

# Captcha - SUPPRIMÉ : reCAPTCHA c'est de la merde, on utilise un honeypot
# gem 'recaptcha'

# Ordering/Sorting
gem 'acts_as_list', '~> 1.0'

# Compatibility - Version plus récente de psych
gem 'psych', '~> 5.0'

group :development, :test do
  # Debugging
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'pry-byebug'
  gem 'pry-rails'

  # Environment variables
  gem 'dotenv-rails'

  # Testing
  gem 'rspec-rails' # Modern testing framework
  gem 'factory_bot_rails' # Test data generation
end

group :development do
  # Development server
  gem 'web-console'

  # Performance monitoring
  gem 'listen', '~> 3.3'

  # Spring (development mode acceleration)
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Code quality
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
end

group :test do
  # System testing
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

# Windows compatibility
gem 'tzinfo-data', platforms: %i[windows jruby]
