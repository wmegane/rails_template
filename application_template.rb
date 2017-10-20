opening_txt = <<-TXT

  ＿人人人人人人人人人人人人人人人人人人人人人人人人人人＿
  ＞　Double Megane Rails Application Template　＜
  ￣Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^YY￣

TXT
puts opening_txt

require 'open-uri'
end_point = 'https://raw.githubusercontent.com/wmegane/rails_template/master'

# ソースファイルのパスを設定
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

# Gemfile
# ----------------------------------------------------------------
gem 'devise'
gem 'sidekiq'
gem 'whenever', require: false
gem 'active_decorator'
gem 'rollbar'

gem_group :development do
  gem 'guard'
  gem 'guard-rubocop'
  gem 'guard-livereload', require: false # ソースを修正するとブラウザが自動でロードされ、画面を作るときに便利
  gem 'rails-erd'                        # rake-erdコマンドでActiveRecordからER図を作成できる
  gem 'bullet'                           # n+1問題を発見
  gem 'annotate'                         # Add a comment summarizing the current schema
  gem 'view_source_map'
  # Capistrano
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails-console'
  gem 'capistrano3-nginx'
  gem 'capistrano3-puma'
  gem 'capistrano-bundler'
  gem 'slackistrano'
end

gem_group :development, :test do
  gem 'dotenv-rails'
  gem 'letter_opener'

  # pry関連
  gem 'pry-rails'          # rails cの対話式コンソールがirbの代わりにリッチなpryになる
  gem 'pry-doc'            # pry中に show-source [method名] でソース内を読める
  gem 'pry-byebug'         # binding.pryをソースに記載すると、ブレイクポイントとなりデバッグが可能になる
  gem 'pry-stack_explorer' # pry中にスタックを上がったり下がったり行き来できる

  # エラー処理
  gem 'better_errors'     # 開発中のエラー画面をリッチにする
  gem 'binding_of_caller' # 開発中のエラー画面にさらに変数の値を表示する

  # コンソール表示整形
  gem 'hirb'              # モデルの出力結果を表形式で表示する
  gem 'hirb-unicode'      # hirbの日本語などマルチバイト文字の出力時の出力結果がすれる問題に対応
  gem 'awesome_print'     # Rubyオブジェクトに色をつけて表示して見やすくなる

  # テスト関連
  gem 'rspec-rails'        # rspec本体
  gem 'factory_girl_rails' # テストデータ作成
  gem 'faker'              # 本物っぽいテストデータの作成
  gem 'faker-japanese'     # 本物っぽいテストデータの作成（日本語対応）
end


# run 'bundle install --path vendor/bundler --without production'
run 'bundle install --without production'


# devise
if yes? 'use devise?(yes/no)'
  generate 'devise:install'
  run 'wget https://gist.githubusercontent.com/kaorumori/7276cec9c2d15940a3d93c6fcfab19f3/raw/a8c4f854988391dd345f04ff100441884c324f2a/devise.ja.yml -P config/locales/'

  copy_file 'src/root/application.html.erb', 'app/views/layouts/application.html.erb'

  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
  generate "devise:views", model_name
end

# config
# ----------------------------------------------------------------
# locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

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

# config/database.yml
remove_file 'config/database.yml'
database_setting_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/database.yml')
create_file 'config/database.yml', database_setting_file.read

# config/environments/development.rb
# inject_into_file 'config/environments/development.rb', <<RUBY, after: 'config.assets.debug = true'
# ここに改行を入れること!!
# config.action_mailer...........
# end
# RUBY
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

inject_into_file 'config/routes.rb', <<RUBY, after: 'Rails.application.routes.draw do'

  if Rails.env.production?
    constraints subdomain: "#{ENV['SIDEKIQ_SUBDOMAIN']}" do
      require 'sidekiq/web'
      mount Sidekiq::Web => '/sidekiq'
    end
  else
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
RUBY

# Dockerfile
docker_file = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/Dockerfile')
create_file 'Dockerfile', docker_file.read

# docker-compose.yml
docker_compose = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/docker-compose.yml')
create_file 'docker-compose.yml', docker_compose.read

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

# sidekiq_config
sidekiq_initializer = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/sidekiq.rb')
create_file 'config/initializers/sidekiq.rb', sidekiq_initializer.read

sidekiq_yml = open('https://raw.githubusercontent.com/wmegane/rails_template/master/src/root/sidekiq.yml')
create_file 'config/sidekiq.yml', sidekiq_yml.read



# insert app name to .env
prepend_file '.env', "APP_NAME=#{app_name}\n"

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

# CircleCI
# ----------------------------------------------------------------
copy_file 'src/root/config.yml', '.circleci/config.yml'

# misc
# ----------------------------------------------------------------
# remove files
remove_file 'README.rdoc'

# set up spring
run 'bundle exec spring binstub --all'

# DB migration
# docker使うのでいったんコメントアウトアウト
# rake 'db:migrate'

# annotate 設定ファイルの作成
run 'bundle exec rails g annotate:install'

# githubのissue,PRのテンプレートファイル
copy_file 'src/root/ISSUE_TEMPLATE.md', '.github/ISSUE_TEMPLATE.md'
copy_file 'src/root/PULL_REQUEST_TEMPLATE.md', '.github/PULL_REQUEST_TEMPLATE.md'

# git
# ----------------------------------------------------------------
# .gitignore
run 'gibo OSX Ruby Rails JetBrains SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /config\/secret.yml/, ''
append_file '.gitignore', "# Ignore the mysql database.\n/db/mysql_data"

after_bundle do
  git :init
  git add: "."
  git commit: "-m 'Initial commit'"
end
