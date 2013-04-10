gem "haml", ">= 4.0.0"
gem "jquery-rails"
gem "acts_as_indexed"
gem "globalize3", "~> 0.3.0"
gem "paper_trail", "~> 2.7.1"
gem "ancestry"
gem "friendly_id", "~> 4.0.9"
gem "stringex"
gem "devise", :git => "git://github.com/chengz/devise.git"
gem "cancan", ">= 1.6.9"
gem "simple_form", "~> 2.0.4"
gem "client_side_validations", "~> 3.2.5"
gem "client_side_validations-simple_form", "~> 2.0.1"
gem "bootstrap-sass", "~> 2.3.0.0"
gem "carrierwave", "~> 0.6.2"
gem 'fog'
gem 'mini_magick'
gem 'uuid'
# make sure we have deployment key setup on the server
# see aqmin.com:deploy
gem 'aqmin', :git => "git@bitbucket.org:chengz/aqmin.git"

gem_group :development do
  gem 'annotate'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  # Deploy with Capistrano
  gem 'capistrano'
  gem "haml-rails"
end
gem_group :test do
  gem "rspec-rails"
  gem "generator_spec"
  gem 'ammeter'
  gem 'fuubar'
  gem "shoulda-matchers"
  gem "factory_girl_rails"
  gem "database_cleaner"
end

insert_into_file 'Gemfile', :after => "group :assets do\n" do
  "  gem 'font-awesome-rails'\n"
end
uncomment_lines 'Gemfile', /'therubyracer'/
uncomment_lines 'Gemfile', /'unicorn'/

run 'bundle install'

# install aqmin app
generate("rspec:install")
generate("aqmin:install")
remove_file 'app/views/layouts/application.html.erb'
rake("aqmin:install:migrations")
route('mount Aqmin::Engine => "/", :as => "aqmin"')
gsub_file 'config/application.rb', "config.active_record.whitelist_attributes = true" do |match|
  match = "config.active_record.whitelist_attributes = false"
end

# add action mailer config for development
insert_into_file "config/environments/development.rb", :after => "config.action_mailer.raise_delivery_errors = false\n" do
  "\n  # added for devise
  config.action_mailer.default_url_options = { :protocol => 'https', :host => 'localhost' }\n"
end

insert_into_file "config/environments/development.rb", :after => "config.active_support.deprecation = :log\n" do
  "\n  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger.const_get(ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].upcase : 'DEBUG')\n"
end

# add content.css to asset precompile list and uncomment assets precompile
gsub_file 'config/environments/production.rb', "search.js" do |match|
  match = "content.css"
end
uncomment_lines 'config/environments/production.rb', /'config.assets.precompile'/

# setup database
if yes?("Would you like to config your database to use postgres?")
  db_username = ask("What is the username you use to access the database for development?")
  db_username = "default" if db_username.blank?
  dev_db_name = ask("What would you like the database name for development? [app_dev]")
  dev_db_name = "app_dev" if dev_db_name.blank?
  test_db_name = ask("What would you like the database name for test? [app_test]")
  test_db_name = "app_test" if test_db_name.blank?
  remove_file "config/database.yml"
  create_file 'config/database.yml' do
      <<-RUBY
development: &dev
  adapter: postgresql
  encoding: unicode
  database: dev_db_name
  pool: 5
  username: db_username

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *dev
  database: test_db_name
RUBY
  end
  comment_lines "Gemfile", /sqlite3/
  gsub_file "config/database.yml", "db_username", db_username
  gsub_file "config/database.yml", "dev_db_name", dev_db_name
  gsub_file "config/database.yml", "test_db_name", test_db_name
  if yes?("Do you want to create these databases?")
    run "createdb #{dev_db_name}"
    run "createdb #{test_db_name}"
  end
end

# run some rake tasks
rake('db:migrate')
rake('db:test:prepare')
rake('aqmin:initialize')

# remove vendor folder
remove_dir('vendor')

capify!

git :init

# user section
if yes?("Would you like to install a user section?")
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate("devise", model_name)
end
