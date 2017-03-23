require 'open-uri'

txt = <<-TXT

  ＿人人人人人人人人人人人人人人人人人人人人人人人人人人＿
  ＞　Double Megane Rails Application Template　＜
  ￣Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^Y^YY￣

TXT
puts txt

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

# config
# ----------------------------------------------------------------
# locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'
run 'wget https://raw.githubusercontent.com/tigrish/devise-i18n/master/rails/locales/ja.yml -P config/locales/'

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
# guard_file = open('https://gist.githubusercontent.com/yhara/606476/raw/ee78111c9c352711fcdad07459c4ad7851f9b09d/devise.ja.yml')
# create_file 'Guardfile', guard_file.read

create_file 'Guardfile', %q{
guard :rubocop, cli: '--rails' do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
guard 'livereload' do
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
end
}

# Rubocop
create_file '.rubocop.yml', %q{
AllCops:
  Include:
    - '**/config.ru'
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'script/**/*'
    - 'bundle_bin/*'
    - 'bin/*'
    - 'spec/*'
    - 'test/*'
AsciiComments:
  Enabled: false # 日本語のコメントを許可
Documentation:
  Enabled: false # クラスにコメントを残さない
Style/ClassAndModuleChildren:
  Enabled: false
Style/ClassVars:
  Enabled: false
Metrics/LineLength:
  Enabled: false
MethodLength:
  CountComments: true
  Max: 15
Metrics/AbcSize:
  Max: 20
}

# dotfiles
# ----------------------------------------------------------------
# .pryrc
pryrc_file = open('https://gist.githubusercontent.com/yhara/606476/raw/ee78111c9c352711fcdad07459c4ad7851f9b09d/devise.ja.yml')
create_file '.pryrc', pryrc_file.read

# dotenv-rails
create_file '.env', %q{
YOUR_KEY="YOUR_VALUE"
}

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