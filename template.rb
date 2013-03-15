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
gem "client_side_validations", "~> 3.2.1"
gem "client_side_validations-simple_form", "~> 2.0.1"
gem "bootstrap-sass", "~> 2.3.0.0"
gem "carrierwave", "~> 0.8.0"
gem 'fog'
gem 'mini_magick'
gem 'uuid'
gem 'aqmin', :git => "git@bitbucket.org:chengz/aqmin.git"

gem_group :development, :test do
  gem 'annotate'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  # Deploy with Capistrano
  gem 'capistrano', '~> 2.5.21'

end

insert_into_file 'Gemfile', :after => "group :assets do\n" do
  'gem "font-awesome-rails"'
end
uncomment_lines 'Gemfile', /therubyracer/
uncomment_lines 'Gemfile', /unicorn/

run 'bundle install'

generate("aqmin:install")
rake("aqmin:install:migrations")
route('mount Aqmin::Engine => "/", :as => "aqmin"')
gsub_file 'config/application.rb', "config.active_record.whitelist_attributes = true" do |match|
  match = "config.active_record.whitelist_attributes = false"
end

capify!

git :init

if yes?("Would you like to install a user section?")
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate("devise", model_name)
end
