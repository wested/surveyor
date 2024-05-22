# This file is customized to run specs withing the testbed environemnt
ENV["RAILS_ENV"] ||= 'test'
begin
  require File.expand_path("../../testbed/config/environment", __FILE__)
rescue LoadError => e
  fail "Could not load the testbed app. Have you generated it?\n#{e.class}: #{e}"
end

require 'rspec/rails'

require 'capybara/rails'
require 'capybara/rspec'
require 'factories'
require 'json_spec'
require 'database_cleaner'
require 'rails-controller-testing'

Rails::Controller::Testing.install
# require 'rspec/retry'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

Capybara.javascript_driver = :selenium_chrome_headless


RSpec.configure do |config|
  config.include JsonSpec::Helpers
  config.include SurveyorAPIHelpers
  config.include SurveyorUIHelpers
  config.include WaitForAjax

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # config.expect_with :rspec do |c|
  #   c.syntax = :expect
  # end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # rspec-retry
  # https://github.com/rspec/rspec-core/issues/456
  # config.verbose_retry       = true # show retry status in spec process
  # retry_count                = ENV['RSPEC_RETRY_COUNT']
  # config.default_retry_count = retry_count.try(:to_i) || 1
  # puts "RSpec retry count is #{config.default_retry_count}"
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
  # include factory_bot methods (create, build, etc) for convenience
  config.include FactoryBot::Syntax::Methods

  ## Database Cleaner
  config.before :suite do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do |example|
    # if example.metadata[:clean_with_truncation] || example.metadata[:js]
    #   DatabaseCleaner.strategy = :truncation
    # else
      DatabaseCleaner.strategy = :truncation
    # end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!

  config.raise_errors_for_deprecations!
end
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
JsonSpec.configure do
  exclude_keys "id", "created_at", "updated_at", "uuid", "modified_at", "completed_at"
end
