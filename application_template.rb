require 'open-uri'

txt = <<-TXT

  ＿人人人人人人人人人人人人人人人人人人人人人人人人人人＿
  ＞　Double Megane Rails Application Template　＜
  ￣Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^YY￣

TXT
puts txt

# Gemfile
# ----------------------------------------------------------------
gemfile_source = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/Gemfile')
gemfile_source.read


# run 'bundle install --path vendor/bundler --without production'
run 'bundle install --without production'

# config
# ----------------------------------------------------------------
# locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'
run 'wget https://gist.githubusercontent.com/kaorumori/7276cec9c2d15940a3d93c6fcfab19f3/raw/a8c4f854988391dd345f04ff100441884c324f2a/devise.ja.yml -P config/locales/'

# config/application.rb
application do
  %q{
    config.time_zone = 'Tokyo'
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# config/environments/development.rb
inject_into_file 'config/environments/development.rb', <<RUBY, after: 'config.assets.debug = true'
  config.action_mailer.default_url_options = { host: 'localhost:3000' }
  config.action_mailer.delivery_method = :letter_opener
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
RUBY

# Guard/Rubocop
# ----------------------------------------------------------------
# Guardfile
guard_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/Guardfile')
create_file 'Guardfile', guard_file.read

# Rubocop
rubocop_config_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/rubocop.yml')
create_file '.rubocop.yml', rubocop_config_file.read

# dotfiles
# ----------------------------------------------------------------
# .pryrc
pryrc_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/pryrc')
create_file '.pryrc', pryrc_file.read

# dotenv-rails
env_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/env')
create_file '.env', env_file.read

# Capistrano
# ----------------------------------------------------------------
run 'bundle exec cap install'

inject_into_file 'Capfile', <<RUBY, after: 'Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }'
  require 'capistrano/rbenv'
  require 'capistrano/bundler'
  require 'capistrano/rails/assets'
  require 'capistrano/rails/migrations'
  require 'capistrano/nginx'
  require 'capistrano/puma'
  require 'capistrano/puma/nginx'
  require 'capistrano/rails/console'
  require 'slackistrano/capistrano'
RUBY

# misc
# ----------------------------------------------------------------
# remove files
remove_file 'README.rdoc'

# set up spring
run 'bundle exec spring binstub --all'

# DB migration
rake 'db:migrate'

# annotate 設定ファイルの作成
run 'bundle exec rails g annotate:install'

# git
# ----------------------------------------------------------------
# .gitignore
run 'gibo OSX Ruby Rails JetBrains SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /config\/secret.yml/, ''

after_bundle do
  git :init
  git add: "."
  git commit: "-m 'Initial commit'"
end
