source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.9'

gem 'rails', '~> 7.2.0'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 6.0'
gem 'sprockets-rails'
gem 'sass-rails', '>= 6'
gem 'image_processing', '~> 1.2'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'redis', '~> 5.0'
gem 'bootsnap', require: false

gem 'acts_as_list', '~> 1.0'
gem 'autoprefixer-rails'
gem 'bootstrap', '~> 5.3'
gem 'cloudinary'
gem 'devise'
gem 'simple_form'
gem 'font-awesome-sass'
gem 'has_vimeo_video'
gem 'psych', '~> 5.0'
gem 'rack-cors'
gem 'rails_cloudflare_turnstile'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: %i[windows jruby]
