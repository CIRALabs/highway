source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'

# Use postgresql as the database for Active Record
gem 'pg', '~> 0.15'
#gem 'sqlite3'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# raven for sentry.io
gem "sentry-raven"

gem 'uglifier'

# need CMS code, but not DTLS code, so do not complicate life with
# need for openssl 1.1.1 w/patches.
gem 'openssl', :git => 'https://github.com/CIRALabs/ruby-openssl.git', :branch => 'cms-added'
#gem 'openssl', :path => '../minerva/ruby-openssl'

# for github warning
gem "loofah", ">= 2.2.3"

# used by IP address management in ANIMA ACP
gem 'ipaddress'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

gem 'active_scaffold', :git => 'https://github.com/activescaffold/active_scaffold.git'
gem 'therubyracer'
gem 'sass'
gem 'sass-rails'
gem 'devise', git: 'https://github.com/plataformatec/devise.git', branch: 'master'

# use this to get full decoding of HTTP Accept: headers, to be able to
# split off smime-type=voucher in pkcs7-mime, and other parameters
gem 'http-accept'

# used to generate multipart bodies
gem 'multipart_body', :git => 'https://github.com/AnimaGUS-minerva/multipart_body.git', :branch => 'binary_http_multipart'
#gem 'multipart_body', :path => '../minerva/multipart_body'

gem 'ecdsa',   :git => 'https://github.com/AnimaGUS-minerva/ruby_ecdsa.git', :branch => 'ecdsa_interface_openssl'
#gem 'ecdsa',   :path => '../minerva/ruby_ecdsa'

#gem 'chariwt', :path => '../chariwt'
gem 'chariwt', :git => 'https://github.com/mcr/ChariWTs.git'
gem 'jwt'

gem 'thin'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem "rspec-rails"
  gem "shoulda"
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
end

group :development do
  # Deploy with Capistrano
  gem 'capistrano', :git => 'https://github.com/mcr/capistrano.git', branch: 'per-host-deploy-to'
  #gem 'capistrano', :path => '../capistrano'
  gem 'capistrano-bundler', :git => 'https://github.com/mcr/bundler.git', branch: 'per-host-deploy-to'
  #gem 'capistrano-bundler', :path => '../bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger', :git => 'https://github.com/mcr/passenger.git', branch: 'per-host-deploy-to'
  #gem 'capistrano-passenger', :path => '../passenger'
  gem 'capistrano-rvm'

  # Spring speeds up development by keeping your application running
  #  in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'sprockets', "~> 3.7.2"

  # sometimes does not get installed by default
  gem 'rb-readline'

end

